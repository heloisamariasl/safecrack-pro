# 🔐 SafeCrack Pro: Um cofre com seleção de dígitos por push buttons e displays de 7 segmentos

Projeto em SystemVerilog que implementa um cofre digital utilizando uma Máquina de Estados Finitos em FPGA. O cofre é implementado com entrada de senha via push buttons e display de 7 segmentos. 

---
## Tecnologias

- SystemVerilog  
- FPGA (Placa ALtera DE2-115)

---
## Estrutura do repositório

```
safecrackpro_fsm.sv          — FSM principal
safecrackpro_top.sv          — Top-level (interliga FSM e decodificadores)
safecrackpro_tb.sv           — Testbench (inclui FSM acelerada para simulação)
bcd_to_7segment_anodo.sv     — Decodificador BCD → 7 segmentos (ânodo comum)
safecrackpro.qsf             — Atribuição de pinos para Quartus
README.md                    — Este arquivo
```

---
## Funcionamento

### Botões
- KEY[1] → Confirma e avança
- KEY[2] → Incrementa dígito  
- KEY[3] → Decrementa dígito  
- KEY[0] → Reset  

---

## Estados da FSM

- S0 → S1 → S2 → S3 (digitação da senha)  
- Senha correta (LED verde por 5s)  
- Senha incorreta (LED vermelho por 3s)
- Após o término da temporização, a FSM retorna automaticamente para S0.

### Codificação dos estados (one-hot)

A FSM usa **one-hot encoding**, no mesmo padrão do código base (`safecrack_fsm` apresentado em sala):

```systemverilog
typedef enum logic [5:0] {
    S0           = 6'b000001,  // dígito 0
    S1           = 6'b000010,  // dígito 1
    S2           = 6'b000100,  // dígito 2
    S3           = 6'b001000,  // dígito 3
    SENHA_CERTA  = 6'b010000,  // LEDs verdes por 5 s
    SENHA_ERRADA = 6'b100000   // LEDs vermelhos por 3 s
} state_t;
```

Como há **6 estados**, o vetor precisa de **6 bits**, um bit exclusivo por estado. O código base tinha 5 estados e por isso usava `logic [4:0]`. A regra geral do one-hot é: largura do vetor = número de estados.

---
## Diagrama de estados

![Diagrama de estados](/Diagrama/DIAGRAMA-ESTADOS-SD.png)

**Notas:**
- Em **S0, S1, S2, S3**: `btn[1]` incrementa o dígito ativo (wrap 9→0), `btn[2]` decrementa (wrap 0→9), `btn[0]` confirma e avança.
- A verificação acontece **na transição de S3**, ao pressionar confirmar.
- `rstn` (KEY[0]) é reset assíncrono global — retorna para S0 a partir de qualquer estado.

---
## Mapeamento de botões e displays

| Sinal físico | Sinal interno | Função                          |
|:------------:|:-------------:|:--------------------------------|
| KEY\[0\]     | `rstn`        | Reset assíncrono global         |
| KEY\[1\]     | `btn[0]`      | Confirma dígito / avança estado |
| KEY\[2\]     | `btn[1]`      | Incrementa dígito ativo         |
| KEY\[3\]     | `btn[2]`      | Decrementa dígito ativo         |
| HEX3         | `seg_pos1`    | Dígito 0 (S0 — mais signif.)    |
| HEX2         | `seg_pos2`    | Dígito 1 (S1)                   |
| HEX1         | `seg_pos3`    | Dígito 2 (S2)                   |
| HEX0         | `seg_pos4`    | Dígito 3 (S3 — menos signif.)   |
| HEX4         | `seg_cur_pos` | Índice do dígito ativo (1..4)   |
| LEDG\[8:0\]  | `led_green`   | Senha correta (5 s)             |
| LEDR\[17:0\] | `led_red`     | Senha errada (3 s)              |

---
## Requisitos

### Detecção de borda única (sem repetição ao segurar)

```systemverilog
btn_pos  = ~btn;               // inverte: ativo-alto
btn_edge = btn_pos & ~btn_prev; // flanco 0→1 somente
```
`btn_prev` é registrado a cada clock — manter o botão pressionado não gera nova borda.

### Wrap-around

```systemverilog
// incremento
next_digits[n] = (digits_reg[n] == 4'd9) ? 4'd0 : digits_reg[n] + 4'd1;
// decremento
next_digits[n] = (digits_reg[n] == 4'd0) ? 4'd9 : digits_reg[n] - 4'd1;
```

### Verificação e temporização

A comparação ocorre diretamente na transição de S3 ao receber `btn_edge[0]`.  
O contador de 28 bits é pré-carregado com `CNT_OK = 249_999_999` (5 s) ou  
`CNT_ERR = 149_999_999` (3 s) e decrementado a cada ciclo.

### Senha configurável via parâmetro

```systemverilog
safecrackpro_fsm #(
    .DIGIT0(4'd1),  // primeiro dígito  (HEX3)
    .DIGIT1(4'd2),
    .DIGIT2(4'd3),
    .DIGIT3(4'd4)   // quarto dígito    (HEX0)
) fsm_inst (...);
```
---

## Como simular

### ModelSim / Questa

```tcl
vlog -sv safecrackpro_fsm.sv safecrackpro_top.sv safecrackpro_tb.sv bcd_to_7segment_anodo.sv
vsim safecrackpro_tb
add wave -r /*
run -all
```
---
## Known Issues e limitações

| # | Descrição | Impacto | Workaround |
|---|-----------|---------|------------|
| 1 | Sem debounce de hardware — botões físicos ruidosos podem gerar dupla borda. | Baixo na DE2-115 | Adicionar contador de debounce (~20 ms = 1 000 000 tics) |
| 2 | HEX4 permanece exibindo "4" durante SENHA_CERTA / SENHA_ERRADA. | Estético | Forçar `seg_cur_pos = 7'b1111111` nesses estados no top-level |
| 3 | A senha é definida em tempo de síntese e não pode ser alterada pelo usuário durante a execução. | Limitação funcional | Implementar modo de configuração e armazenamento da senha |

## Autores

Projeto desenvolvido por estudantes de sistemas digitais.
- [Ana Maria Ribeiro](https://github.com/anaribeirowxz)
- [David Sales](https://github.com/davdsales)
- [Heloisa Leite](https://github.com/heloisamariasl)
- [Maria Gabriela](https://github.com/mghsgab)
- [Kailani Yoná](https://github.com/Kailaniyona)