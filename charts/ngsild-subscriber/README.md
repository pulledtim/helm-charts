# ngsild-subscriber

![Version: 2.2.1](https://img.shields.io/badge/Version-2.2.1-informational?style=flat-square) ![AppVersion: v0.0.1](https://img.shields.io/badge/AppVersion-v0.0.1-informational?style=flat-square)

A Helm chart for creating subscriptions in NGSI-LD context brokers

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| pulledtim | <tim.smyth@fiware.org> |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backoffLimit | int | `10` |  |
| broker | string | `"context-broker:1026"` |  |
| deployment.image.pullPolicy | string | `"IfNotPresent"` |  |
| deployment.image.repository | string | `"curlimages/curl"` |  |
| deployment.image.tag | string | `"8.9.0"` |  |
| fullnameOverride | string | `""` | option to override the fullname config in the _helpers.tpl |
| nameOverride | string | `""` | option to override the name config in the _helpers.tpl |
| subscription | string | `"{}\n"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
