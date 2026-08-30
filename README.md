# ClínicaCare — Desafio Final Fábrica de Software Workshop 2026.2

Projeto de dados de uma clínica médica fictícia (ClínicaCare), cobrindo os 4
módulos do desafio: modelagem de dados, SQL, Python/Machine Learning e
visualização de dados (dashboard).

## Estrutura do repositório

```
1_Modelagem/     Modelo conceitual (E-R) e modelo lógico
2_SQL/           Script SQL (DDL + DML + DQL) e análise das consultas
3_Python/        Notebook de análise + ML (previsão de no-show) e dataset limpo
4_Power_BI/      Dados, dashboard interativo e documento de insights
```

## Módulo 1 — Modelagem de Dados
- `1_Modelagem/Modelo_Conceitual_ER.png` — diagrama E-R (dbdiagram.io)
- `1_Modelagem/Modelo_Logico.txt` — modelo lógico relacional (tabelas, PK/FK, tipos)
- `1_Modelagem/schema.dbml`

## Módulo 2 — SQL
- `2_SQL/clinica_care.sql` — schema `clinica_care` completo (DDL, dados de
  exemplo, updates, agregações, 5 tipos de JOIN)
- `2_SQL/Analise_Consultas.docx` — descrição e insight de cada consulta

## Módulo 3 — Python + Machine Learning
- `3_Python/analise_clinica.ipynb` — extração dos dados, features, gráficos
  (Matplotlib), modelo de Regressão Logística para previsão de no-show,
  avaliação (acurácia/precisão/recall/F1/ROC-AUC) e comparação com Decision Tree
- `3_Python/dados_limpos.csv` — dataset tratado usado no treinamento

## Módulo 4 — Dashboard (visualização de dados)
- `4_Power_BI/dados.xlsx` — dados em esquema estrela (fato_consultas,
  fato_pagamentos, dim_pacientes, dim_medicos, dim_especialidades,
  dim_convenios, dim_calendario)
- `4_Power_BI/Dashboard_ClinicaCare.html` — **dashboard interativo** (abrir
  direto no navegador, não precisa instalar nada): 4 cards de KPI, filtros de
  especialidade e convênio, e 4 gráficos (barras, colunas, pizza, linha) com
  formatação condicional por cor
- `4_Power_BI/Insights_Dashboard.docx` — análise escrita dos principais
  insights de cada visualização e recomendações
- `4_Power_BI/medidas_dax_sugeridas.md` — cheat-sheet de medidas DAX (extra)

### Nota sobre a ferramenta do Módulo 4

O desafio pede um arquivo `.pbix` do Power BI. Ao longo do projeto isso foi
tentado por várias vias (Power BI Service, Power BI Desktop via VM Windows,
Tableau Public, Power BI Desktop em máquina Windows dedicada), cada uma
esbarrando em um bloqueio técnico diferente (bloqueio de download no Service,
loop de boot na VM, bug de relacionamento de dados no Tableau, desempenho
insuficiente da máquina Windows dentro do prazo). Com autorização expressa do
superior responsável, o dashboard final foi construído como uma página HTML
interativa (JavaScript + Plotly.js), cobrindo os mesmos requisitos funcionais
pedidos no desafio (KPIs, os 4 gráficos, filtros/slicers e formatação
condicional). O histórico completo dessa decisão está documentado em
`CHECKLIST_CONFORMIDADE.md` (na raiz do projeto local), para transparência
com o avaliador.

## Consistência dos dados

Os números (total de pacientes, receita, taxa de ocupação, taxa de no-show)
são consistentes entre os módulos 2 (SQL), 3 (Python) e 4 (dashboard), todos
derivados da mesma base `clinica_care`.
