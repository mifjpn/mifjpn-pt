# Mifjpn-PT

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.20%20--%2026.x-brightgreen.svg)](https://www.minecraft.net/)
[![Iris + Sodium](https://img.shields.io/badge/Iris%20%2B%20Sodium-Required-orange.svg)](https://irisshaders.dev/)
[![LabPBR](https://img.shields.io/badge/Material-LabPBR%201.3-purple.svg)](https://shaderlabs.org/wiki/LabPBR_Material_Standard)
[![Clean-Room](https://img.shields.io/badge/Architecture-100%25%20Procedural%20Clean--Room-teal.svg)](LICENSE)

**Clean-room, physically grounded screen-space path-traced shader pack for Minecraft Java Edition (`1.20` – `26.x`).**

Engineered from scratch in pure procedural GLSL with zero external binary lookup textures, `Mifjpn-PT` combines R2-sampled Screen-Space Path-Traced Global Illumination (SSPT GI), temporal variance-guided denoising, analytical spherical atmosphere optics, and full **Minecraft 26.x Reversed-Z** shadow pipeline support under the permissive **MIT License**.

---

## Rendering Architecture

| Stage | Technical Implementation |
| :--- | :--- |
| **Global Illumination (SSPT)** | R2 quasirandom sequence + branchless Pixar orthonormal basis (ONB) cosine-hemisphere ray marching with 1-bounce indirect color bleeding |
| **Temporal-Spatial Denoiser** | Variance-guided 1st/2nd moment clamping (`colortex` history) paired with normal/depth edge-stopping À-Trous spatial reconstruction |
| **Direct Lighting & BRDF** | Height-correlated Smith-GGX microfacet specular, Schlick/conductor $F_0$ presets, diffuse roughness, and `PBR_SSS` subsurface wrap |
| **Shadow Pipeline (MC 26.x Ready)** | Radial-warped shadow map (`shadowPlayer=true`, `shadow.culling=false` for Reversed-Z), Vogel-disk PCF, colored glass transmittance, and **10-step Screen-Space Contact Shadows** |
| **Surface Detail (LabPBR 1.3)** | 32-step Parallax Occlusion Mapping (`POM`) with self-shadowing + automatic luma-gradient normal synthesis for vanilla resource packs |
| **Atmosphere & Volumes** | Analytical Chapman airmass Rayleigh / Mie / Chappuis-ozone scattering, multi-scattered 3D volumetric clouds with physical camera wake, and boreal/snowy aurora storms |
| **Ocean & Water Optics** | 28-band Jacobian-advected wave spectrum, exact unpolarized dielectric Fresnel reflectance, Beer-Lambert spectral absorption, and Hessian determinant underwater caustics |
| **Dimension Engines** | **Nether:** 3D volumetric soot, tectonic magma crust, updraft embers · **End:** Domain-warped nebula, solar eclipse corona, 3D void mist sea |
| **Color & Exposure** | Snow-albedo-compensated temporal auto-exposure feeding an **Open-Toe Filmic** tone mapper to preserve deep shadow contrast and bright snowfields simultaneously |

---

## Key Highlights

- **Zero Binary Blobs, 100% Mathematical Synthesis**: Every noise field, wave spectrum, star dome, nebula, and caustic pattern is synthesized analytically in shader code — keeping the archive compact, auditable, and strictly MIT-clean.
- **High-Contrast Daylight & Crisp Silhouettes**: Balanced solar-to-sky irradiance ratio (~5:1) ensures sunlit architecture pops against cool cerulean sky-lit shadows while warm indirect GI bounces naturally into overhangs and alleys.
- **Full Entity & First-Person Player Shadows**: Accurately blocks light across `entityTranslucent` layers (player skins, 3D skin layers, and armor) alongside micro-scale contact shadows on stairs, fences, and foliage.
- **Bilingual UI**: Complete **English (`en_us`)** and **Japanese (`ja_jp`)** option menus with 6 performance presets (`POTATO` / `LOW` / `MEDIUM` / `HIGH` / `ULTRA` / `RTX_MAX`).

---

## Requirements & Installation

1. Install **Sodium** and **Iris Shaders** for Minecraft Java Edition `1.20` – `26.x`.
2. Download `Mifjpn-PT.zip` from [**Releases**](../../releases) (or the repository root) and place it directly into `.minecraft/shaderpacks/` *(do not unzip)*.
3. Launch Minecraft and select `Mifjpn-PT.zip` under **Options → Video Settings → Shader Packs**.

---

## Mod Compatibility

- **Distant Horizons**: Native LOD G-Buffer and atmospheric perspective integration.
- **Physics Mod Pro**: Native **Ocean Physics (`Ocean v3`)** vertex and fragment hook integration isolated cleanly to water passes.
  - *Minecraft 26.3 Note*: Keep **Ocean Physics** enabled as desired. If entity or terrain shadows disappear when using Physics Mod, set **Options → Physics Settings → Smoke** to **Off** so Iris shadow framebuffers remain uninterrupted.

## Sister Edition

- **Mifjpn-PT-Clouds**: Derivative edition featuring a 32 km spherical dual-layer cloud engine (high-altitude Cirrostratus/Cirrocumulus veils + high-base Bénard-cell cumulus) while retaining lightweight PT GI evaluation.

## License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---
---

# Mifjpn-PT（日本語ドキュメント）

**Minecraft Java Edition (`1.20` – `26.x` / Iris + Sodium)** 向けにフルスクラッチで設計・実装された、クリーンルーム設計・**MITライセンス**のスクリーンスペース・パストレーシングシェーダーパックです。

外部のバイナリ3Dノイズテクスチャ等を一切含まず、すべての光学散乱・波浪・大気・マテリアル処理を純粋なプロシージャルGLSL数理モデルのみで構築。**Minecraft 26.x の Reversed-Z 描画パイプライン**にも完全対応しています。

---

## レンダリング・アーキテクチャ

| パイプライン階層 | 技術仕様・実装モデル |
| :--- | :--- |
| **パストレーシング GI (SSPT)** | R2準乱数列 ＋ 分岐なし Pixar 直交基底（ONB）によるコサイン重点半球レイマーチングと1バウンス色滲み（カラーブリーディング） |
| **時間軸・空間分散デノイザー** | 1次・2次モーメント分散クランプ付き時間軸蓄積 ＋ 法線・深度エッジ保持 À-Trous 空間フィルタリング |
| **物理ベース直接光 ＆ BRDF** | 高度相関 Smith-GGX マイクロファセット鏡面BRDF、導体 $F_0$ プリセット、表面下散乱（`PBR_SSS`） |
| **高精細シャドウ (MC 26.x 対応)** | 放射歪みシャドウマップ（`shadowPlayer=true`、`shadow.culling=false` による Reversed-Z 対応）、VogelディスクPCF、ステンドグラス色透過影、**10ステップ接触影（`CONTACT_SHADOWS`）** |
| **LabPBR 1.3 ＆ 自動法線** | 自己陰影付き視差オクルージョンマッピング（`POM`）＋ バニラテクスチャの輝度勾配からの自動法線合成（`GENERATED_NORMALS`） |
| **球面大気散乱 ＆ 3Dボリューム** | チャップマン気柱近似による Rayleigh / Mie / 成層圏オゾン（Chappuis帯）散乱、航跡かき分け対応3Dボリューム雲、極地・雪原オーロラストーム |
| **28バンド海洋波浪 ＆ 水中光学** | ヤコビアン移流28波スペクトル合成、非偏光誘電体の厳密フレネル反射、ランベルト・ベール分光吸収、ヘッセ行列式による水底コースティクス |
| **異次元専用3Dボリューム** | **ネザー:** 3D煤煙・溶岩プレート地殻・上昇火の粉 ／ **ジ・エンド:** ドメインワープ星雲・皆既日食コロナ・奈落の3D雲海 |
| **露出制御 ＆ トーンマップ** | 雪原の高アルベド白飛びを防ぐ雪景色補正付き自動露出 ＋ 暗部階調とハイライトを両立する **Open-Toe Filmic** トーンマッピング |

---

## 主な特徴

- **外部バイナリ資産ゼロの100%クリーンルーム実装**: 雲・波・星空・星雲・コースティクスに至るまでシェーダー内の数式のみで生成しており、軽量かつ権利関係が完全にクリアな MIT ライセンス構成です。
- **引き締まった日陰とPTバウンス光のコントラスト**: 直射日光とクールな空色環境光の明暗比を最適化し、日向の壁や地面から軒下・路地裏へ回り込む暖かい間接バウンス光を自然に描写します。
- **一人称・三人称プレイヤー影と接地感の徹底**: `entityTranslucent`（プレイヤースキン・3Dスキンレイヤー・防具）の不透明ピクセル完全遮光に加え、スクリーンスペース接触影により階段・柵・足元の浮きを抑えます。
- **6段階プリセット ＆ 日本語メニュー完備**: `POTATO` から `RTX_MAX` までのプロファイルと、日本語（`ja_jp`）・英語（`en_us`）の完全ローカライズ設定画面を収録しています。

---

## 導入方法

1. Minecraft Java Edition（`1.20` 〜 `26.x`）に **Sodium** と **Iris Shaders** を導入します。
2. [**Releases**](../../releases)（またはリポジトリ直下）から `Mifjpn-PT.zip` をダウンロードし、解凍せずに `.minecraft/shaderpacks/` フォルダへ配置します。
3. ゲーム内の **設定 → ビデオ設定 → シェーダーパック** から `Mifjpn-PT.zip` を選択して適用します。

---

## Mod 連携・注意事項

- **Distant Horizons**: 遠景 LOD チャンクの G-Buffer 統合および大気遠近フォグにネイティブ対応しています。
- **Physics Mod Pro**: 水面パスにおける **海洋物理（`Ocean v3`）** メッシュ変位にネイティブ対応しています。
  - *MC 26.3 環境での補足*: 海洋物理（Ocean）はそのまま利用可能です。Physics Mod 併用時にプレイヤーや地形の影が消える場合は、**設定 → Physics Settings → Smoke（煙）** のみ **Off** に設定してください。

## 派生エディション

- **Mifjpn-PT-Clouds**: PT間接光の軽快さを維持したまま、32km 球殻投影による「高層巻層雲・うろこ雲 ＋ 高高度対流セル積雲」の二層大気エンジンを搭載した派生版です。

## ライセンス

**MIT License** の下で公開・配布されています。全文は [`LICENSE`](LICENSE) を参照してください。
