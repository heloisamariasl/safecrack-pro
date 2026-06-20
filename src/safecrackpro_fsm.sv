// Nosso diagrama de estados funciona assim
//   btn[1] (KEY[2]) - incrementa dígito (9 - 0)
//   btn[2] (KEY[3]) - decrementa dígito (0 - 9)
//   btn[0] (KEY[1]) - confirma e avança para o próximo estado
// KEY[0] - Reset

module safecrackpro_fsm #( // Começa a definir uma caixa(o module)
    parameter logic [3:0] DIGIT0 = 4'd1,  // Primeiro dígito da senha
    parameter logic [3:0] DIGIT1 = 4'd2,  // Segundo dígito da senha
    parameter logic [3:0] DIGIT2 = 4'd3,  // Terceiro dígito da senha
    parameter logic [3:0] DIGIT3 = 4'd4   // Quarto dígito da senha
)(
    input  logic        clk, // Clock do sistema
    input  logic        rstn, // Reset (0 = reinicia o sistema)

    input  logic [2:0]  btn,// Representa os três botões utilizados pelo usuário

    output logic [3:0][3:0] digits, // Armazena os 4 dígitos mostrados no display da placa
    output logic [1:0]      current_position_idx, // Indica qual posição da senha o usuário está digitando
    output logic [17:0]     led_red, // Controla os 18 leds vermelhos da placa
    output logic [8:0]      led_green // Controla os 9 leds verdes
);

// Define os estados do sistema
    typedef enum logic [5:0] {
        S0           = 6'b000001,  // editando dígito 0
        S1           = 6'b000010,  // editando dígito 1
        S2           = 6'b000100,  // editando dígito 2
        S3           = 6'b001000,  // editando dígito 3
        SENHA_CERTA  = 6'b010000,  // LEDs verdes por 5 s
        SENHA_ERRADA = 6'b100000   // LEDs vermelhos por 3 s
    } state_t;

    state_t state, next_state;

    
// Contadores de tempo
    localparam int CNT_OK  = 50_000_000 * 5 - 1;  //  Quantidade de ciclos para esperar 5s
    localparam int CNT_ERR = 50_000_000 * 3 - 1;  //  Quantidade de ciclos para esperar 3s

    logic [27:0] delay_cnt, next_delay_cnt;//contador utilizado para medir o tempo de espera e armazenar o próximo valor que será carregado no contador

//Controle dos botões
//  Solto = 1 e pressionado = 0, por isso os sinais são invertidos facilitando o uso
    // btn_pos (estado atual dos botões após a inversão)
    // btn_prev (estado dos botões no ciclo anterior)
    // btn_edge (indica que um botão acabou de ser pressionado)
    logic [2:0] btn_pos, btn_prev, btn_edge;

    always_comb begin// inverte os sinais
        btn_pos  = ~btn;
        btn_edge = btn_pos & ~btn_prev;
    end

// Armazena os números digitados pelo usuário
    logic [3:0][3:0] digits_reg, next_digits;

// Lógica sequencial
// Executado a cada pulso do clock, ele é responsável por armazenar os valores calculados
// Se o reset for pressionado, o sistema zera, se não os novos valores são salvos

    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            state      <= S0;
            btn_prev   <= '0;
            delay_cnt  <= '0;
            digits_reg <= '0;
        end else begin
            state      <= next_state;
            btn_prev   <= btn_pos;
            delay_cnt  <= next_delay_cnt;
            digits_reg <= next_digits;
        end
    end

    
// Lógica combinacional (Calcula os próximos valores da FSM)
    
    always_comb begin
        next_state     = state;
        next_delay_cnt = delay_cnt;
        next_digits    = digits_reg;

        unique case (state)

            // S0 - edição do primeiro dígito
            S0: begin
                if (btn_edge[1])       // incrementa
                    next_digits[0] = (digits_reg[0] == 4'd9) ? 4'd0 : digits_reg[0] + 4'd1;
                else if (btn_edge[2])  // decrementa
                    next_digits[0] = (digits_reg[0] == 4'd0) ? 4'd9 : digits_reg[0] - 4'd1;
                else if (btn_edge[0])  // confirma e avança para o próximo dígito
                    next_state = S1;
            end

            //S1 - edição do segundo dígito
            S1: begin
                if (btn_edge[1])
                    next_digits[1] = (digits_reg[1] == 4'd9) ? 4'd0 : digits_reg[1] + 4'd1;
                else if (btn_edge[2])
                    next_digits[1] = (digits_reg[1] == 4'd0) ? 4'd9 : digits_reg[1] - 4'd1;
                else if (btn_edge[0])
                    next_state = S2;
            end

            //S2 - edição do terceiro dígito
            S2: begin
                if (btn_edge[1])
                    next_digits[2] = (digits_reg[2] == 4'd9) ? 4'd0 : digits_reg[2] + 4'd1;
                else if (btn_edge[2])
                    next_digits[2] = (digits_reg[2] == 4'd0) ? 4'd9 : digits_reg[2] - 4'd1;
                else if (btn_edge[0])
                    next_state = S3;
            end

            // S3 - edição do quarto dígito
            S3: begin
                if (btn_edge[1])
                    next_digits[3] = (digits_reg[3] == 4'd9) ? 4'd0 : digits_reg[3] + 4'd1;
                else if (btn_edge[2])
                    next_digits[3] = (digits_reg[3] == 4'd0) ? 4'd9 : digits_reg[3] - 4'd1;
                else if (btn_edge[0]) begin
                    // Verifica a senha 
                    if (digits_reg[0] == DIGIT0 && digits_reg[1] == DIGIT1 &&
                        digits_reg[2] == DIGIT2 && digits_reg[3] == DIGIT3) begin
                        next_state     = SENHA_CERTA;
                        next_delay_cnt = 28'(CNT_OK);
                    end else begin
                        next_state     = SENHA_ERRADA;
                        next_delay_cnt = 28'(CNT_ERR);
                    end
                end
            end
            
            // Senha certa - LEDs verdes acesos por 5 s, depois volta para S0
            SENHA_CERTA: begin
                if (delay_cnt == '0) begin
                    next_state     = S0;
                    next_digits    = '0; // Limpa os dígitos
                    next_delay_cnt = '0;
                end else begin
                    next_delay_cnt = delay_cnt - 28'd1;
                end
            end

            // SENHA_ERRADA - LEDs vermelhos por 3 s, depois volta para S0
            SENHA_ERRADA: begin
                if (delay_cnt == '0) begin
                    next_state     = S0;
                    next_digits    = '0;
                    next_delay_cnt = '0;
                end else begin
                    next_delay_cnt = delay_cnt - 28'd1;
                end
            end

            default: next_state = S0;
        endcase
    end

// Saídas da FSM
    //Envia os dígitos para os displays
    assign digits = digits_reg;

    //Indica qual posição da senha está sendo editada
    always_comb begin
        unique case (state)
            S0:           current_position_idx = 2'd0;
            S1:           current_position_idx = 2'd1;
            S2:           current_position_idx = 2'd2;
            S3,
            SENHA_CERTA,
            SENHA_ERRADA: current_position_idx = 2'd3;
            default:      current_position_idx = 2'd0;
        endcase
    end

    assign led_green = (state == SENHA_CERTA)  ? 9'h1FF   : 9'h000; // Acende os LEDs verdes quando a senha está certa
    assign led_red   = (state == SENHA_ERRADA) ? 18'h3FFFF : 18'h000; // Acende os LEDs vermelhos quando a senha está errada

endmodule
 