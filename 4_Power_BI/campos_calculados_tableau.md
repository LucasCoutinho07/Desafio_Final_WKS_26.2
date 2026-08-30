# Campos calculados sugeridos — Dashboard ClínicaCare (Tableau Public)

> Ferramenta trocada de Power BI para **Tableau Public**, com autorização do
> superior do Lucas (VM do Power BI Desktop travou em loop de boot; Tableau
> Public roda nativo em Mac Apple Silicon, sem VM). Este arquivo substitui
> `medidas_dax_sugeridas.md` (Power BI), adaptando as mesmas medidas para a
> sintaxe de campos calculados do Tableau. Ver nota no README sobre a troca.

Cole essas fórmulas em **Analisar > Criar Campo Calculado** (ou clique com o
botão direito em qualquer espaço em branco no painel de Dados > Criar Campo
Calculado). Ajuste nomes de campo se o Tableau importar as colunas com nomes
diferentes dos usados aqui (confira o nome exato no painel de Dados após
conectar o `dados.xlsx`).

## Antes de tudo: conectar os dados e relacionar as tabelas

1. Abra o Tableau Public > **Conectar > Microsoft Excel** > selecione
   `dados.xlsx`.
2. Na aba **Fonte de Dados**, arraste as 7 planilhas para o canvas:
   `fato_consultas`, `fato_pagamentos`, `dim_pacientes`, `dim_medicos`,
   `dim_especialidades`, `dim_convenios`, `dim_calendario`.
3. O Tableau (versão atual usa **Relacionamentos**, não JOINs físicos, por
   padrão — é o equivalente ao modelo de estrela do Power BI) tenta detectar
   as ligações automaticamente pelo nome da coluna. Confira/ajuste clicando
   na linha entre duas tabelas:
   - `fato_consultas.id_paciente` → `dim_pacientes.id_paciente`
   - `fato_consultas.id_medico` → `dim_medicos.id_medico`
   - `fato_consultas.id_especialidade` → `dim_especialidades.id_especialidade`
   - `fato_pagamentos.id_consulta` → `fato_consultas.id_consulta`
   - `dim_pacientes.id_convenio` → `dim_convenios.id_convenio`
   - `fato_consultas.data_consulta` → `dim_calendario.Data`

   Diferente do Power BI, **não existe** um botão "marcar como tabela de
   datas" — não precisa disso. Se preferir simplificar e não relacionar
   `dim_calendario`, o Tableau também cria uma hierarquia de datas automática
   (Ano > Trimestre > Mês > Dia) direto em cima de `fato_consultas.data_consulta`.
   A vantagem de relacionar `dim_calendario` é ter os nomes dos meses em
   português (Janeiro, Fevereiro...) garantidos, independente da configuração
   regional do computador — recomendo manter, já que o resto do projeto está
   todo em pt-BR.

## KPIs / Cards (pedidos no desafio)

```
Total Pacientes
COUNTD([Id Paciente])
```

```
Total Receita
SUM([Valor])
```
(soma todo pagamento — some um filtro de página/planilha por
`Status Pagamento = "Pago"` se quiser só receita já recebida)

```
Receita Recebida
SUM(IF [Status Pagamento] = "Pago" THEN [Valor] END)
```

```
Taxa de Ocupação
SUM(IF [Status] = "Realizada" THEN 1 ELSE 0 END)
/
SUM(IF [Status] <> "Agendada" THEN 1 ELSE 0 END)
```
(considera "ocupação" = % de consultas passadas que efetivamente
aconteceram; ajuste a definição se o professor pedir outra). Formate como
porcentagem no próprio pill (botão direito no campo > Formatar Padrão de
Números > Porcentagem).

## Para o gráfico de linha (taxa de no-show ao longo do tempo)

```
Taxa de No-Show
SUM(IF [Status] = "Faltou" THEN 1 ELSE 0 END)
/
SUM(IF [Status] = "Realizada" OR [Status] = "Faltou" OR [Status] = "Cancelada" THEN 1 ELSE 0 END)
```

Monte o gráfico: arraste `Ano` e `Mes` de `dim_calendario` (ou a hierarquia
automática de `Data Consulta`) para **Colunas**, e `Taxa de No-Show` para
**Linhas**. Troque o Marca para "Linha". Formate o eixo Y como porcentagem.

## Para o gráfico de barras (consultas por especialidade)

Arraste `dim_especialidades.Nome Especialidade` para **Linhas** e
`Total Consultas` (abaixo) para **Colunas**. Marca = "Barra".

```
Total Consultas
COUNT([Id Consulta])
```

## Para o gráfico de colunas (faturamento por mês)

**Colunas:** `dim_calendario.AnoMes` (ou hierarquia Ano/Mês automática).
**Linhas:** `Receita Recebida` (ou `Total Receita`, dependendo do que fizer
mais sentido pro seu professor). Marca = "Barra" (vertical).

## Para o gráfico de pizza (pacientes por convênio)

Marca = "Pizza". **Ângulo:** `Total Pacientes`. **Cor/Rótulo:**
`dim_convenios.Nome` (via relacionamento `dim_pacientes → dim_convenios`).

## Campo calculado extra sugerido (opcional, bom para formatação condicional)

```
Ticket Médio
[Total Receita] / [Total Consultas]
```

Útil para formatação condicional (ex.: destacar médicos ou especialidades
acima/abaixo do ticket médio geral, via **Cor** no painel Marcas + uma régua
de cores divergente) — um dos itens "recomendados" do desafio.

## Filtros (slicers) e formatação condicional

- Arraste `dim_especialidades.Nome Especialidade`, `dim_convenios.Nome` e/ou
  `dim_calendario.Ano` para o painel **Filtros** e clique com o botão direito
  > **Mostrar Filtro** para virar um controle interativo no dashboard
  (equivalente ao slicer do Power BI).
- Formatação condicional: no Tableau isso é feito colocando um campo em
  **Cor** (painel Marcas) e ajustando a régua de cores (clique na legenda de
  cores > Editar Cores). Ex.: cor da barra de "Total Consultas" por
  especialidade variando conforme `Taxa de No-Show` daquela especialidade.
- Para juntar tudo num **Dashboard** (não só planilhas soltas): crie uma aba
  nova do tipo **Dashboard**, arraste as planilhas pra dentro, redimensione,
  e adicione título geral + os filtros marcados como "Aplicar a: Planilhas
  Selecionadas" nas que fizer sentido.

## Salvando o entregável

**Arquivo > Salvar Como...** e escolha **Tableau Packaged Workbook (.twbx)**
— isso empacota os dados junto, então o arquivo funciona sozinho sem precisar
do `dados.xlsx` ao lado. Salve como
`4_Power_BI/Dashboard_ClinicaCare.twbx` (mantém a mesma pasta e nome-base
sugeridos pelo PDF, só troca a extensão de `.pbix` para `.twbx`, já que o
PDF pedia especificamente Power BI mas seu superior autorizou o Tableau
Public no lugar).
