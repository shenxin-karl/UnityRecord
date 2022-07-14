# 学习Shader需要的数学基础

# 坐标系

![image-20220715001314259](C:/Users/Administrator/AppData/Roaming/Typora/typora-user-images/image-20220715001314259.png)

**除了在观察空间中, 其他都是在左手系**

## Unity 内置的变换矩阵

| 变量名               | 描述                               |
| -------------------- | ---------------------------------- |
| `UNITY_MATRIX_MVP`   | `project * view * model`           |
| `UNITY_MATRIX_MV`    | `view * model`                     |
| `UNITY_MATRIX_V`     | `view`                             |
| `UNITY_MATRIX_P`     | `project`                          |
| `UNITY_MATRIX_VP`    | `project * view`                   |
| `UNITY_MATRIX_T_MV`  | `inverse(view * model)`            |
| `UNITY_MATRIX_IT_MV` | `transpose(inverse(view * model))` |
| `_Object2World`      | `model`                            |
| `_World2Object`      | `inverse(model)`                   |

## Unity 内置变量

| 变量名                        | 类型       | 描述                                                         |
| ----------------------------- | ---------- | ------------------------------------------------------------ |
| `_WorldSpaceCameraPos`        | `float3`   | 相机世界空间中的位置                                         |
| `_ProjectionParams`           | `float4`   | `x = 1.0`<br />`y = Near`<br />`z = Far`<br />`w = 1.0 + 1.0/Far` |
| `_ScreenParams`               | `float4`   | `x = width`<br />`y = height`<br />`z = 1 + 1 / width`<br />`y = 1 + 1 / height` |
| `_ZBufferParams`              | `float4`   | `x = 1 - Far/Near`<br />`y = Far/Near`<br />`z = x / Far` <br />`w = y / Far` |
| `unity_OrthoParams`           | `float4`   | x = width, y = height, z 没有定义, w = 1.0 是正交相机, w = 0.0 透视投影 |
| `unity_CameraProject`         | `float4x4` | 相机中的投影矩阵                                             |
| `unity_CameraInvProject`      | `float4x4` | 相机投影逆矩阵                                               |
| `unity_CameraWorldClipPlanes` | `float4`   | 相机在 6 个裁剪屏幕在世界空间下的等式<br />按照 左, 右, 上, 下, 近, 远 |

