# Medidas DAX sugeridas — Dashboard ClínicaCare

Cole essas medidas no Power BI Desktop (aba **Modelagem > Nova medida**, com a
tabela `fato_consultas` ou `fato_pagamentos` selecionada, conforme indicado).
Ajuste nomes de tabela/coluna se você renomear algo ao importar.

## Antes de tudo: relacionamentos e tabela de datas

Depois de importar `dados.xlsx` (Página Inicial > Obter Dados > Excel),
o Power BI deve detectar os relacionamentos automaticamente pelos nomes de
coluna (`id_paciente`, `id_medico`, `id_especialidade`, `id_convenio`,
`id_consulta`). Confira em **Modelagem > Gerenciar relacionamentos**:

- `fato_consultas[id_paciente]` → `dim_pacientes[id_paciente]`
- `fato_consultas[id_medico]` → `dim_medicos[id_medico]`
- `fato_consultas[id_especialidade]` → `dim_especialidades[id_especialidade]`
- `fato_pagamentos[id_consulta]` → `fato_consultas[id_consulta]`
- `dim_pacientes[id_convenio]` → `dim_convenios[id_convenio]`
- `dim_calendario[Data]` → `fato_consultas[data_consulta]`

Marque `dim_calendario` como **tabela de datas** (clique na tabela > aba
Ferramentas de Tabela > Marcar como Tabela de Data > coluna `Data`). Isso
habilita os recursos de inteligência de tempo do DAX (`TOTALYTD`, etc.) e faz
os slicers de ano/mês funcionarem direito.

## KPIs / Cards (pedidos no desafio)

```dax
Total Pacientes = DISTINCTCOUNT(dim_pacientes[id_paciente])
```

```dax
Total Receita = SUM(fato_pagamentos[valor])
```
(soma todo pagamento — some um filtro de página/visual por `status_pagamento = "Pago"` se quiser só receita já recebida)

```dax
Receita Recebida = CALCULATE(SUM(fato_pagamentos[valor]), fato_pagamentos[status_pagamento] = "Pago")
```

```dax
Taxa de Ocupação =
VAR ConsultasRealizadas = CALCULATE(COUNTROWS(fato_consultas), fato_consultas[status] = "Realizada")
VAR ConsultasTotais = CALCULATE(COUNTROWS(fato_consultas), fato_consultas[status] <> "Agendada")
RETURN DIVIDE(ConsultasRealizadas, ConsultasTotais)
```
(considera "ocupação" = % de consultas passadas que efetivamente aconteceram; ajuste a definição se seu professor pedir outra)

## Para o gráfico de linha (taxa de no-show ao longo do tempo)

```dax
Taxa de No-Show =
VAR Faltas = CALCULATE(COUNTROWS(fato_consultas), fato_consultas[status] = "Faltou")
VAR Passadas = CALCULATE(COUNTROWS(fato_consultas), fato_consultas[status] IN {"Realizada", "Faltou", "Cancelada"})
RETURN DIVIDE(Faltas, Passadas)
```

Use no eixo X do gráfico de linha: `dim_calendario[Ano]` e `dim_calendario[NumeroMes]` (ou a hierarquia de data automática) — arraste `Taxa de No-Show` como valor, formate como porcentagem.

## Para o gráfico de barras (consultas por especialidade)

Basta arrastar `dim_especialidades[nome_especialidade]` no eixo e uma medida:

```dax
Total Consultas = COUNTROWS(fato_consultas)
```

## Para o gráfico de colunas (faturamento por mês)

Eixo X: `dim_calendario[AnoMes]` (ou hierarquia Ano/Mês). Valor: `Receita Recebida` (ou `Total Receita`, dependendo do que fizer mais sentido pro seu professor).

## Para o gráfico de pizza (pacientes por convênio)

Legenda: `dim_convenios[nome]`. Valor: `Total Pacientes` (via relacionamento `dim_pacientes → dim_convenios`).

## Medida extra sugerida (opcional, bom para formatação condicional)

```dax
Ticket Médio = DIVIDE([Total Receita], [Total Consultas])
```

Útil para uma formatação condicional (ex.: destacar médicos ou especialidades acima/abaixo do ticket médio geral) — um dos itens "recomendados" do desafio.
