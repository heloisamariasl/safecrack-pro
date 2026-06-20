# 🔐 SafeCrack Pro: Um cofre com seleção de dígitos por push buttons e displays de 7 segmentos

Projeto em SystemVerilog que implementa um cofre digital utilizando uma Máquina de Estados Finitos em FPGA.

---
## ⚙️ Funcionamento

### Botões
- KEY[1] → Incrementa dígito  
- KEY[2] → Decrementa dígito  
- KEY[3] → Confirma e avança  
- KEY[0] → Reset  

---

## 🧠 Estados da FSM

- S0 → S1 → S2 → S3 (digitação da senha)  
- Senha correta (LED verde por 5s)  
- Senha incorreta (LED vermelho por 3s)  

---

## 🛠️ Tecnologias

- SystemVerilog  
- FPGA (DE2-115) - Placa
---

## 👨‍💻 Autores

Projeto desenvolvido por estudantes de sistemas digitais.
- [Ana Maria Ribeiro](https://github.com/anaribeirowxz)
- [David Sales](https://github.com/davdsales)
- [Heloisa Leite](https://github.com/heloisamariasl)
- [Maria Gabriela](https://github.com/mghsgab)
- [Kailani Yoná](https://github.com/Kailaniyona)
