# Tutorial de referência — Scan Chain

> **Aviso de autoria:** o material original presente nesta pasta foi fornecido pelo professor da disciplina **98G10-04 — Confiabilidade e Segurança de Hardware**, da PUCRS, para utilização como tutorial durante a realização do Trabalho T2.

## Autoria do material

O tutorial original **não foi desenvolvido pelos integrantes deste grupo**.

O material foi disponibilizado no contexto da disciplina pelo:

**Prof. Anderson Domingues**  
Pontifícia Universidade Católica do Rio Grande do Sul — PUCRS

Os direitos e a autoria do conteúdo original permanecem com seus respectivos autores e responsáveis.

---

# Finalidade desta pasta

O material foi utilizado exclusivamente como **referência acadêmica** para a primeira etapa do Trabalho T2.

O objetivo dessa etapa era reproduzir um fluxo de **Design for Testability (DfT)** com foco em **Scan Chain**, utilizando as ferramentas Cadence.

A partir desse tutorial foram estudadas e reproduzidas as etapas de:

1. leitura do RTL;
2. elaboração do projeto;
3. aplicação de constraints;
4. síntese lógica;
5. geração dos relatórios de área e potência;
6. verificação das regras de DfT;
7. substituição dos registradores por células scan;
8. conexão das scan chains;
9. geração de padrões ATPG;
10. simulação e validação dos padrões gerados.

---

# Uso no Trabalho T2

Após a reprodução do tutorial, o grupo desenvolveu sua própria adaptação do fluxo para o módulo:

```text
stream_merge
```

O trabalho desenvolvido pelo grupo inclui:

- adaptação das constraints;
- inserção de Scan Chain no `stream_merge`;
- geração ATPG;
- simulação full-scan;
- exploração paramétrica;
- automação da síntese;
- automação dos experimentos;
- extração automática dos resultados;
- análise de área, potência e cobertura de teste.

Os arquivos desenvolvidos pelo grupo encontram-se principalmente em:

```text
../rtl/
```

e:

```text
../synthesis/
```

---

# Evidências da reprodução do tutorial

Os prints e resultados obtidos durante a reprodução do tutorial estão disponíveis em:

```text
../figures/1/
```

Essas evidências demonstram a execução do fluxo utilizado como base para a posterior adaptação ao `stream_merge`.

---

# Resultados do projeto desenvolvido pelo grupo

Os resultados da exploração realizada sobre o `stream_merge` encontram-se em:

```text
../results/
```

O relatório completo encontra-se em:

```text
../report/
```

---

# Aviso sobre redistribuição

Este material está sendo mantido nesta pasta exclusivamente para fins de **documentação acadêmica e reprodutibilidade do trabalho realizado**.

A presença do arquivo original neste repositório **não implica transferência de autoria ou direitos aos integrantes do grupo**.

Caso a redistribuição pública do material original não seja autorizada pelos responsáveis pela disciplina, o arquivo deverá ser removido do repositório público, mantendo-se apenas este `README.md` e a referência ao tutorial disponibilizado no ambiente oficial da disciplina.

---

## Integrantes do grupo

- Pedro Henrique de Ros
- Douglas Cavalheiro Carvalho
- Matheus Susin Timmers

**Disciplina:** 98G10-04 — Confiabilidade e Segurança de Hardware  
**PUCRS — 2026**
