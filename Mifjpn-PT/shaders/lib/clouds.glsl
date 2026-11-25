// Mifjpn-PT | Volumetric Cloud Deck, Multi-Scattering & Wake Vorticity
// SPDX-License-Identifier: MIT
#ifndef MIFJPN_PT_CLOUDS_GLSL
#define MIFJPN_PT_CLOUDS_GLSL
#if defined VOLUMETRIC_CLOUDS && !defined NETHER && !defined END

const float CLOUD_SIGMA_EXT = 0.065;
const float CLOUD_MAX_DIST  = 9000.0;

vec2 cloudEntry = vec2(-100.0, 0.0);

float cloudBase() { return CLOUD_ALTITUDE; }
float cloudTop()  { return CLOUD_ALTITUDE + CLOUD_THICKNESS; }

vec2 cloudWind() {
    return vec2(0.851, 0.525) * (frameTimeCounter * 3.0 * CLOUD_SPEED);
}

float cloudCoverAmount() {
    return mix(CLOUD_COVERAGE, 0.95, rainStrength);
}

float valueNoise3D(vec3 p) {
    vec3 cell = floor(p);
    vec3 frac = p - cell;
    vec3 w    = frac * frac * (3.0 - 2.0 * frac);

    float c000 = hash13(cell);
    float c100 = hash13(cell + vec3(1.0, 0.0, 0.0));
    float c010 = hash13(cell + vec3(0.0, 1.0, 0.0));
    float c110 = hash13(cell + vec3(1.0, 1.0, 0.0));
    float c001 = hash13(cell + vec3(0.0, 0.0, 1.0));
    float c101 = hash13(cell + vec3(1.0, 0.0, 1.0));
    float c011 = hash13(cell + vec3(0.0, 1.0, 1.0));
    float c111 = hash13(cell + vec3(1.0, 1.0, 1.0));

    float z0 = mix(mix(c000, c100, w.x), mix(c010, c110, w.x), w.y);
    float z1 = mix(mix(c001, c101, w.x), mix(c011, c111, w.x), w.y);
    return mix(z0, z1, w.z);
}

float cloudCoverageMap(vec2 worldXZ) {
    vec2 uv  = (worldXZ + cloudWind()) * (1.0 / 640.0);
    float f  = noise2D(uv) * 0.56
             + noise2D(uv * 2.13 + 7.3) * 0.29
             + noise2D(uv * 4.71 + 2.1) * 0.15;
    float cv = cloudCoverAmount();
    return smoothstep(1.0 - cv - 0.06, 1.0 - cv + 0.30, f);
}

float cloudDensity(vec3 worldPos, float mipLod) {
    float normH = (worldPos.y - cloudBase()) * (1.0 / CLOUD_THICKNESS);
    if (normH <= 0.0 || normH >= 1.0) return 0.0;

    float cover = cloudCoverageMap(worldPos.xz);
    if (cover <= 0.002) return 0.0;

    float anvilTop = mix(0.30, 1.0, cover);
    float profile  = cover * smoothstep(0.0, 0.07, normH) * (1.0 - smoothstep(anvilTop * 0.45, anvilTop, normH));
    if (profile <= 0.002) return 0.0;

    vec2 drift   = cloudWind();
    vec3 sampleP = vec3(
        worldPos.x + drift.x * 1.15,
        worldPos.y - frameTimeCounter * 0.25 * CLOUD_SPEED,
        worldPos.z + drift.y * 1.15
    );

    float billow = valueNoise3D(sampleP * (1.0 / 46.0));
    if (mipLod < 0.5) {
        billow = billow * 0.68 + valueNoise3D(sampleP * (1.0 / 15.0) + 3.1) * 0.32;
    }

    float eroded = profile - (1.0 - billow) * mix(0.62, 0.45, normH);
    return saturate(eroded * 2.6);
}

#ifdef CLOUD_INTERACTION
bool isCameraNearCloudDeck() {
    return (cameraPosition.y > cloudBase() - 24.0) && (cameraPosition.y < cloudTop() + 24.0);
}

float evalCloudWake(vec3 worldPos, out vec3 vortexShift) {
    vortexShift = vec3(0.0);
    vec3  rel   = worldPos - cameraPosition;
    float dist  = length(rel);
    if (dist > 40.0) return 1.0;

    float t     = frameTimeCounter;
    vec3  vel   = (cameraPosition - previousCameraPosition) / max(frameTime, 1e-3);
    float speed = length(vel);
    if (speed > 120.0) {
        vel   = vec3(0.0);
        speed = 0.0;
    }

    float flutter  = valueNoise3D(rel * 0.35 + vec3(t * 0.7, t * 1.1, t * 0.5));
    float cavityR  = (2.6 + 0.08 * speed) * (0.75 + 0.50 * flutter);
    float maskKeep = smoothstep(cavityR * 0.55, cavityR * 1.45, dist);

    if (speed > 1.5) {
        vec3  trailDir = -vel / speed;
        float trailPos = dot(rel, trailDir);
        float trailLen = min(speed * 1.2, 30.0);
        if (trailPos > 0.0 && trailPos < trailLen) {
            float radialOff = length(rel - trailDir * trailPos);
            float coneR     = cavityR * (1.0 - 0.75 * (trailPos / trailLen));
            maskKeep       *= smoothstep(coneR * 0.40, coneR * 1.30, radialOff);
        }
    }

    float nearFalloff = exp(-dist * (1.0 / 7.0));
    vec3  turb = vec3(
        valueNoise3D(rel * 0.20 + t * 0.9),
        valueNoise3D(rel * 0.20 + 7.0 - t * 0.8),
        valueNoise3D(rel * 0.20 + 13.0 + t * 0.7)
    ) - 0.5;
    vortexShift = turb * (12.0 * nearFalloff * (0.6 + 0.02 * speed));

    float elapsed = t - cloudEntry.x;
    if (elapsed < 0.0) elapsed += 3600.0;
    float impact = abs(cloudEntry.y);
    if (impact > 0.01 && elapsed < 4.0) {
        float ringR = 2.0 + 7.0 * sqrt(elapsed);
        float dRing = (dist - ringR) * (1.0 / 2.2);
        maskKeep   += exp(-dRing * dRing) * impact * exp(-elapsed * 0.769) * 1.4;
    }
    return maskKeep;
}
#endif

float cloudDensityAt(vec3 worldPos, float mipLod) {
#ifdef CLOUD_INTERACTION
    if (isCameraNearCloudDeck()) {
        vec3  vortexShift;
        float wakeGain = evalCloudWake(worldPos, vortexShift);
        return saturate(cloudDensity(worldPos + vortexShift, mipLod) * wakeGain);
    }
#endif
    return cloudDensity(worldPos, mipLod);
}

float dualLobeCloudPhase(float cosTheta, float lobeScale) {
    return phaseHGn(cosTheta,  0.80 * lobeScale) * 0.72
         + phaseHGn(cosTheta, -0.25 * lobeScale) * 0.28;
}

vec4 volumetricClouds(
    vec3  rayOrigin,
    vec3  rayDir,
    float geomDist,
    float jitter,
    vec3  lightDir,
    vec3  lightRad,
    vec3  zenithAmb,
    vec3  horizAmb
) {
    float yBot = cloudBase();
    float yTop = cloudTop();
    float tEnter, tExit;

    if (abs(rayDir.y) < 1e-4) {
        if (rayOrigin.y < yBot || rayOrigin.y > yTop) return vec4(0.0, 0.0, 0.0, 1.0);
        tEnter = 0.0;
        tExit  = CLOUD_MAX_DIST;
    } else {
        float invDy = 1.0 / rayDir.y;
        float t0    = (yBot - rayOrigin.y) * invDy;
        float t1    = (yTop - rayOrigin.y) * invDy;
        tEnter      = max(min(t0, t1), 0.0);
        tExit       = max(t0, t1);
    }

    tExit = min(min(tExit, geomDist), min(tEnter + 1600.0, CLOUD_MAX_DIST));
    if (tExit <= tEnter) return vec4(0.0, 0.0, 0.0, 1.0);

    int   stepCount = CLOUD_STEPS;
    float stepLen   = (tExit - tEnter) / float(stepCount);
    bool  inDeck    = (rayOrigin.y > yBot && rayOrigin.y < yTop);
    float stepGrow  = 1.0;
    if (inDeck) {
        stepLen  = min(stepLen, 3.0);
        stepGrow = 1.24;
    }

    float currT    = tEnter + stepLen * jitter;
    float cosTheta = dot(rayDir, lightDir);
    float extCoeff = CLOUD_SIGMA_EXT * CLOUD_DENSITY;
    float stormDim = (1.0 - 0.55 * rainStrength) * CLOUD_BRIGHTNESS;

    float ph0 = dualLobeCloudPhase(cosTheta, 1.00);
    float ph1 = dualLobeCloudPhase(cosTheta, 0.50);
    float ph2 = dualLobeCloudPhase(cosTheta, 0.25);

    vec3  accumRad  = vec3(0.0);
    float trans     = 1.0;
    float firstHitT = -1.0;

    for (int i = 0; i < 64; ++i) {
        if (i >= stepCount || currT > tExit) break;

        vec3  samplePos = rayOrigin + rayDir * currT;
        float dens      = cloudDensityAt(samplePos, 0.0);

        if (dens > 0.004) {
            if (firstHitT < 0.0) firstHitT = currT;
            float relH = saturate((samplePos.y - yBot) * (1.0 / CLOUD_THICKNESS));

            float sunTau = (cloudDensityAt(samplePos + lightDir * 3.0,  1.0) * 6.0
                          + cloudDensityAt(samplePos + lightDir * 13.8, 1.0) * 15.6
                          + cloudDensityAt(samplePos + lightDir * 41.9, 1.0) * 40.5) * extCoeff;

            float multScat = exp(-sunTau)        * ph0
                           + exp(-sunTau * 0.40) * ph1 * 0.50
                           + exp(-sunTau * 0.16) * ph2 * 0.25;

            float powder = 1.0 - 0.65 * exp(-dens * extCoeff * 18.0);
            vec3  inScat = (lightRad * (multScat * powder * 0.55)
                          + zenithAmb * (mix(0.30, 1.00, relH) * 0.85)
                          + horizAmb  * (0.18 * (1.0 - relH))) * stormDim;

            float stepTrans = exp(-extCoeff * dens * stepLen);
            accumRad += trans * inScat * (1.0 - stepTrans);
            trans    *= stepTrans;
            if (trans < 0.01) break;
        }

        currT   += stepLen;
        stepLen *= stepGrow;
    }

    if (firstHitT < 0.0) return vec4(0.0, 0.0, 0.0, 1.0);

    float distFade  = exp(-firstHitT * 3.0e-4);
    float horizFade = smoothstep(0.0, 0.06, abs(rayDir.y) + (inDeck ? 1.0 : 0.0));
    float visWeight = distFade * mix(0.35, 1.0, horizFade);
    return vec4(accumRad * visWeight, mix(1.0, trans, visWeight));
}

vec4 cloudsFlat(vec3 rayDir, vec3 lightDir, vec3 lightRad, vec3 zenithAmb) {
    float planeY = cloudBase() + CLOUD_THICKNESS * 0.35;
    if (rayDir.y < 0.02 || cameraPosition.y > planeY) return vec4(0.0);

    vec2  hitXZ   = cameraPosition.xz + rayDir.xz * ((planeY - cameraPosition.y) / rayDir.y);
    float cover   = cloudCoverageMap(hitXZ);
    float opacity = smoothstep(0.04, 0.45, cover) * smoothstep(0.02, 0.18, rayDir.y) * 0.95;
    float lining  = pow(max(dot(rayDir, lightDir), 0.0), 6.0);

    vec3 col = zenithAmb * 0.90 + lightRad * (0.30 + 0.45 * (1.0 - cover) + 0.60 * lining);
    col     *= (1.0 - 0.55 * rainStrength) * CLOUD_BRIGHTNESS;
    return vec4(col, opacity);
}

float cloudShadow(vec3 worldPos, vec3 lightDir) {
    if (lightDir.y < 0.03) return 1.0;
    float planeY = cloudBase() + CLOUD_THICKNESS * 0.30;
    if (worldPos.y > planeY) return 1.0;

    vec2  projXZ = worldPos.xz + lightDir.xz * ((planeY - worldPos.y) / lightDir.y);
    float cover  = cloudCoverageMap(projXZ);
    return 1.0 - 0.78 * CLOUD_SHADOW_STRENGTH * smoothstep(0.04, 0.55, cover);
}

#endif
#endif
