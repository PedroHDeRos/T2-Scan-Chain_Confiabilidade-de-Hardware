# T2 — Scan Chain e Design for Testability

Projeto desenvolvido para a disciplina **98G10-04 — Confiabilidade e Segurança de Hardware**, da **Pontifícia Universidade Católica do Rio Grande do Sul (PUCRS)**.

O trabalho explora técnicas de **Design for Testability (DfT)** com foco em **Scan Chain**, utilizando as ferramentas **Cadence Genus**, **Cadence Modus** e **Cadence Xcelium**.

Inicialmente foi reproduzido o tutorial disponibilizado na disciplina. Em seguida, o fluxo foi adaptado para o módulo parametrizável `stream_merge`, incluindo inserção de registradores scan, geração de padrões ATPG, simulação dos vetores de teste e exploração do impacto dos parâmetros do projeto sobre área, potência e cobertura de teste.

---

## Autores

- **Pedro Henrique de Ros**
- **Douglas Cavalheiro Carvalho**
- **Matheus Susin Timmers**

**Professor:** Anderson Domingues  
**Disciplina:** 98G10-04 — Confiabilidade e Segurança de Hardware  
**Instituição:** PUCRS

---

## Objetivos

O trabalho foi dividido em quatro etapas principais:

1. Reproduzir o tutorial fornecido na disciplina utilizando **Genus** e **Modus**.
2. Adaptar o fluxo para o módulo `stream_merge`, realizando a inserção de registradores scan.
3. Gerar e executar padrões de teste ATPG, incluindo scripts de automação.
4. Explorar diferentes configurações de `DATA_W`, `DEPTH` e `WMAX`, avaliando:
   - quantidade de registradores scan;
   - área antes e depois da inserção de DfT;
   - overhead de área;
   - potência estimada;
   - cobertura ATPG.

---

## Ferramentas utilizadas

O desenvolvimento e os experimentos foram executados no ambiente computacional disponibilizado pela PUCRS.

Principais ferramentas:

- **Cadence Genus 21.12**
- **Cadence Modus 21.10**
- **Cadence Xcelium 23.03**
- **SystemVerilog**
- **Tcl**
- **Shell Script**
- **Python 3**
- Biblioteca tecnológica CMOS de **65 nm** disponibilizada no ambiente da disciplina

> **Observação:** alguns scripts possuem referências aos caminhos das bibliotecas e módulos instalados no ambiente da PUCRS. Para executar o projeto em outra infraestrutura, esses caminhos podem precisar ser modificados.

---

# Módulo analisado

O projeto utiliza o módulo SystemVerilog `stream_merge`.

O circuito realiza a união de dois fluxos de pacotes utilizando:

- interface `valid/ready`;
- FIFO interno;
- marcação de pacotes por `sop` e `eop`;
- arbitragem weighted round-robin;
- garantia de atomicidade de pacote;
- parâmetros configuráveis.

Os parâmetros principais são:

| Parâmetro | Descrição | Valor padrão |
|---|---|---:|
| `DATA_W` | Largura dos dados | 32 |
| `DEPTH` | Profundidade da FIFO | 8 |
| `WMAX` | Peso máximo do árbitro | 7 |

---

# Estrutura do repositório

```text
T2-Scan/
│
├── figures/
│   ├── 1/
│   │   └── Evidências da execução do tutorial
│   │
│   └── 2/
│       └── Evidências da execução com stream_merge
│
├── report/
│   ├── T2_Overleaf_Project/
│   │   └── Projeto LaTeX utilizado no Overleaf
│   │
│   └── T2_Scan_Chain.pdf
│
├── results/
│   ├── results_summary.csv
│   └── results_final.csv
│
├── rtl/
│   └── stream_merge.sv
│
├── synthesis/
│   ├── constraint/
│   │   └── stream_merge.sdc
│   │
│   ├── dft_setup.tcl
│   ├── run_config.tcl
│   ├── run_sweep.sh
│   ├── run_sweep_all.sh
│   ├── run_atpg_all.sh
│   ├── retry_atpg_one.sh
│   ├── extract_results.py
│   └── extract_atpg_results.py
│
├── tutorial/
│   ├── README.md
│   └── Material de referência fornecido na disciplina
│
└── README.md
```

---

# Fluxo do trabalho

## 1. Reprodução do tutorial

A primeira etapa consistiu na reprodução do fluxo de Scan Chain disponibilizado como tutorial da disciplina.

O processo envolveu:

1. leitura e elaboração do RTL;
2. aplicação das constraints;
3. síntese lógica;
4. geração de relatórios de área e potência;
5. verificação das regras de DfT;
6. substituição dos registradores por células scan;
7. conexão das scan chains;
8. geração de padrões ATPG no Modus;
9. simulação dos vetores utilizando Xcelium.

### Resultados do tutorial

Foram obtidos:

- **116 registradores scan**;
- **2 scan chains**;
- comprimentos de **16 e 100 registradores**;
- **100% dos registradores elegíveis para scan**;
- cobertura ATPG de aproximadamente **99,97%**;
- simulação full-scan concluída sem falhas.

As evidências desta etapa estão disponíveis em:

```text
figures/1/
```

---

# 2. Adaptação para o `stream_merge`

Após validar o fluxo original, ele foi adaptado para o módulo `stream_merge`.

A configuração padrão utilizada foi:

```text
DATA_W = 32
DEPTH  = 8
WMAX   = 7
```

Após síntese e inserção de DfT foram obtidos:

- **298 registradores scan**;
- **1 scan chain**;
- **100% dos registradores elegíveis para scan**;
- **0 violações DfT**;
- cobertura ATPG de **99,99%**.

Na simulação full-scan foram obtidos:

```text
Total de testes:       47
Testes aprovados:      47
Testes com falha:       0
Miscompares:            0
```

As evidências desta etapa estão disponíveis em:

```text
figures/2/
```

---

# Automação

Como o trabalho exigia a exploração de diferentes parâmetros do módulo, o fluxo foi automatizado.

## `run_config.tcl`

Executa uma configuração individual do projeto.

O script realiza:

```text
read_hdl
    ↓
elaborate parametrizado
    ↓
read_sdc
    ↓
syn_generic
    ↓
syn_map
    ↓
syn_opt
    ↓
relatórios pré-DFT
    ↓
inserção de Scan/DFT
    ↓
relatórios pós-DFT
    ↓
geração dos arquivos para Modus
```

## `run_sweep_all.sh`

Executa automaticamente todas as configurações selecionadas para exploração paramétrica.

## `run_atpg_all.sh`

Automatiza a execução do fluxo ATPG para todas as configurações sintetizadas.

## `retry_atpg_one.sh`

Durante os experimentos foi observada uma instabilidade ocasional do **Modus 21.10** durante sua inicialização.

Este script permite repetir individualmente uma determinada configuração sem refazer toda a síntese.

Exemplo:

```bash
./retry_atpg_one.sh DATA_W32_DEPTH8_WMAX3
```

## Scripts de extração

### `extract_results.py`

Extrai automaticamente:

- área pré-DFT;
- área pós-DFT;
- potência pré-DFT;
- potência pós-DFT;
- número de scan chains;
- número de registradores scan;
- overhead de área e potência.

### `extract_atpg_results.py`

Adiciona aos resultados:

- quantidade de testes ATPG;
- cobertura ATPG;
- cobertura global;
- número de falhas não testadas.

O resultado consolidado é armazenado em:

```text
results_final.csv
```

---

# Execução

## Síntese e inserção de DfT

Entre na pasta:

```bash
cd synthesis
```

Carregue o Genus:

```bash
module purge
module load genus
```

Dê permissão de execução aos scripts, se necessário:

```bash
chmod +x run_sweep_all.sh
```

Execute:

```bash
./run_sweep_all.sh
```

---

# ATPG

Após finalizar a síntese:

```bash
module purge
module load modus/21.10
```

Execute:

```bash
chmod +x run_atpg_all.sh
./run_atpg_all.sh
```

Caso uma configuração individual precise ser executada novamente:

```bash
./retry_atpg_one.sh DATA_W32_DEPTH8_WMAX3
```

---

# Consolidação dos resultados

Após a execução dos experimentos:

```bash
python3 extract_results.py
```

e:

```bash
python3 extract_atpg_results.py
```

Os arquivos consolidados utilizados no relatório estão disponíveis em:

```text
results/
```

---

# Exploração paramétrica

Foram analisadas sete configurações.

| DATA_W | DEPTH | WMAX |
|---:|---:|---:|
| 16 | 8 | 7 |
| 32 | 4 | 7 |
| 32 | 8 | 3 |
| 32 | 8 | 7 |
| 32 | 8 | 15 |
| 32 | 16 | 7 |
| 64 | 8 | 7 |

A configuração:

```text
DATA_W = 32
DEPTH  = 8
WMAX   = 7
```

foi utilizada como referência.

A exploração foi realizada alterando um parâmetro de cada vez, permitindo observar separadamente seu impacto sobre a implementação.

---

# Resultados

## Área, scan registers e ATPG

| DATA_W | DEPTH | WMAX | Scan Regs | Área pré-DFT | Área pós-DFT | ATPG |
|---:|---:|---:|---:|---:|---:|---:|
| 16 | 8 | 7 | 170 | 3621.488 | 4289.085 | 99,99% |
| 32 | 4 | 7 | 155 | 3542.543 | 4143.488 | 99,99% |
| 32 | 8 | 3 | 296 | 5975.422 | 7115.332 | 99,98% |
| 32 | 8 | 7 | 298 | 6034.880 | 7186.277 | 99,99% |
| 32 | 8 | 15 | 300 | 6119.472 | 7278.917 | 99,99% |
| 32 | 16 | 7 | 581 | 11196.465 | 13451.840 | 99,99% |
| 64 | 8 | 7 | 554 | 10807.504 | 12950.883 | 99,99% |

---

# Análise dos resultados

Os experimentos permitiram observar comportamentos distintos entre os parâmetros.

## Influência de `DATA_W`

O aumento da largura dos dados produz um aumento expressivo na quantidade de armazenamento do circuito.

Com:

```text
DATA_W = 16
```

foram encontrados:

```text
170 registradores scan
```

enquanto:

```text
DATA_W = 64
```

resultou em:

```text
554 registradores scan
```

Portanto, `DATA_W` possui impacto significativo tanto na área quanto no tamanho da scan chain.

---

## Influência de `DEPTH`

A profundidade da FIFO também apresentou forte influência.

Para:

```text
DEPTH = 4
```

foram obtidos:

```text
155 registradores scan
```

enquanto:

```text
DEPTH = 16
```

resultou em:

```text
581 registradores scan
```

Isso ocorre porque o aumento da profundidade implica maior quantidade de armazenamento interno.

---

## Influência de `WMAX`

O parâmetro `WMAX` apresentou impacto estrutural significativamente menor.

Mantendo `DATA_W=32` e `DEPTH=8`:

```text
WMAX = 3  → 296 registradores
WMAX = 7  → 298 registradores
WMAX = 15 → 300 registradores
```

Isso indica que o parâmetro afeta principalmente os registradores associados aos créditos do árbitro, e não o armazenamento principal do módulo.

---

# Overhead de Scan Chain

A substituição dos registradores convencionais por células scan e a inserção da lógica DfT aumentaram a área do projeto.

Nos experimentos realizados, o overhead de área ficou aproximadamente entre:

```text
17% e 20%
```

dependendo da configuração utilizada.

Este resultado evidencia o custo estrutural associado à melhoria de controlabilidade e observabilidade proporcionada pelo Scan Test.

---

# Cobertura ATPG

A cobertura permaneceu extremamente elevada em todas as configurações analisadas:

```text
99,98% – 99,99%
```

Seis das sete configurações atingiram:

```text
99,99%
```

A configuração:

```text
DATA_W = 32
DEPTH  = 8
WMAX   = 3
```

apresentou:

```text
ATPG Coverage   = 99,98%
Global Coverage = 99,98%
Untested Faults = 1
```

Mesmo com a alteração dos parâmetros do módulo, a testabilidade permaneceu praticamente constante e próxima de 100%.

---

# Potência

Os valores de potência armazenados em `results_summary.csv` e `results_final.csv` correspondem às estimativas fornecidas pelo **Cadence Genus**.

Esses valores representam a implementação sintetizada e **não devem ser interpretados diretamente como potência durante o deslocamento da scan chain**.

Durante o ATPG, o Modus também indicou situações de elevada atividade de comutação, mostrando que o modo de teste pode apresentar comportamento de potência diferente do modo funcional.

---

# Relatório

O relatório completo está disponível em:

```text
report/
```

A pasta contém:

- projeto fonte em LaTeX;
- arquivos utilizados no Overleaf;
- figuras;
- gráficos;
- PDF final do trabalho.

---

# Tutorial de referência

A pasta:

```text
tutorial/
```

contém o material utilizado na primeira etapa do trabalho.

Esse material foi **fornecido pelo professor da disciplina como tutorial de referência** e **não é de autoria dos integrantes deste grupo**.

Mais informações sobre autoria e finalidade estão disponíveis em:

```text
tutorial/README.md
```

---

# Uso acadêmico

Este repositório foi criado exclusivamente para fins acadêmicos no contexto da disciplina **98G10-04 — Confiabilidade e Segurança de Hardware**, da PUCRS.

Os scripts, automações, análises e relatório produzidos pelo grupo são parte do desenvolvimento do T2.

Materiais fornecidos pela disciplina, pela universidade, pela EnSilica ou por terceiros permanecem sujeitos aos direitos e condições definidos pelos respectivos autores.
