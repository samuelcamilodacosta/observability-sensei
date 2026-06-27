# Métricas DORA

As quatro métricas DORA medem performance de entrega de software:

| Métrica | Definição |
|---------|-----------|
| **Deployment frequency** | Com que frequência você faz deploy |
| **Lead time for changes** | Commit → produção |
| **Change failure rate** | % de deploys que falham |
| **MTTR** | Tempo para recuperar incidente |

## Como observabilidade ajuda

| Métrica | Artefato neste repo |
|---------|---------------------|
| Frequência | CI/CD + gates confiáveis |
| Change failure rate | Production Gate |
| MTTR | `rollback.sh` + logs/métricas com versão |

Próximo: [Rollback](./06-rollback-strategies.md)
