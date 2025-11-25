## 📋 Requisitos do Sistema

Para executar este projeto, você precisará ter instalado em sua máquina:

* **Java (JRE ou JDK):** Necessário para rodar o simulador, já que o MARS é uma aplicação baseada em Java.
* **IDE MARS 4.5:** O *MIPS Assembler and Runtime Simulator*, utilizado para compilar e simular o código Assembly.


## ⚙️ Configuração Obrigatória (MARS 4.5)

Para o jogo funcionar corretamente, as ferramentas devem ser configuradas **exatamente** como abaixo antes de rodar:

### 1. Bitmap Display
Acesse o menu **Tools > Bitmap Display** e configure:

| Configuração | Valor |
| :--- | :--- |
| **Unit Width in Pixels** | `1` |
| **Unit Height in Pixels** | `1` |
| **Display Width in Pixels** | `256` |
| **Display Height in Pixels** | `256` |
| **Base address for display** | `0x10010000 (global data)` |

> **⚠️ Importante:** Após configurar, clique no botão **"Connect to MIPS"**.

### 2. Keyboard and Display MMIO Simulator
Acesse o menu **Tools > Keyboard and Display MMIO Simulator**:

1. Clique no botão **"Connect to MIPS"**.
2. **Atenção:** Durante o jogo, clique dentro da caixa de texto branca desta janela para digitar os comandos (WASD). O teclado não funciona se o foco estiver no editor de código.

---

## 👨‍💻 Autores

Este jogo foi desenvolvido para a disciplina de **Infraestrutura de Hardware** por:

* **Antônio Augusto**
* **Thiago Tahim**
* **Rafael Lyra**
