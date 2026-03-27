#Eduardo Augusto Camacho d'Oliveira Pavin - EduardoPavin
#RA1-12

import sys
import struct
import math

OPERADORES = {'+', '-', '*', '/', '//', '%', '^'}

# codigos de 7 segmentos para digitos 0-9, e o segmento do sinal negativo
SEG7 = [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F]
SEG_NEG = 0x40


def double_to_ieee754(v):
    packed = struct.pack('d', float(v))
    lo, hi = struct.unpack('II', packed)
    return lo, hi


def is_numero(token):
    s = token.lstrip('-')
    if not s:
        return False
    partes = s.split('.')
    if len(partes) > 2:
        return False
    return all(p.isdigit() for p in partes if p) and any(p for p in partes if p)


def is_identificador(token):
    return token.isalpha() and token.isupper() and token != 'RES'


def validar_parenteses(tokens):
    depth = 0
    for t in tokens:
        if t == '(':
            depth += 1
        elif t == ')':
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


# AFD: parseExpressao percorre a linha delegando para o estado corrente.
# cada funcao de estado devolve (proximo_estado, novo_indice)

def parseExpressao(linha):
    tokens = []
    i = 0
    estado = estado_inicial
    while i < len(linha):
        estado, i = estado(linha, i, tokens)
    return tokens


def estado_inicial(linha, i, tokens):
    c = linha[i]
    if c.isspace():
        return estado_inicial, i + 1
    if c in '()':
        tokens.append(c)
        return estado_inicial, i + 1
    if c.isdigit():
        return estado_numero(linha, i, tokens)
    if c == '-':
        # tricky: pode ser operador ou sinal de numero negativo
        ultimo = tokens[-1] if tokens else None
        if i + 1 < len(linha) and linha[i + 1].isdigit():
            if ultimo is None or ultimo in ('(', '+', '-', '*', '/', '//', '%', '^'):
                return estado_numero(linha, i, tokens)
        tokens.append('-')
        return estado_inicial, i + 1
    if c in '+*%^':
        tokens.append(c)
        return estado_inicial, i + 1
    if c == '/':
        if i + 1 < len(linha) and linha[i + 1] == '/':
            tokens.append('//')
            return estado_inicial, i + 2
        tokens.append('/')
        return estado_inicial, i + 1
    if c.isalpha():
        return estado_palavra(linha, i, tokens)
    raise ValueError(f"Token invalido: '{c}'")


def estado_numero(linha, i, tokens):
    inicio = i
    tem_ponto = False
    if linha[i] == '-':
        i += 1
    tem_digito = False
    while i < len(linha):
        c = linha[i]
        if c.isdigit():
            tem_digito = True
            i += 1
        elif c == '.':
            if tem_ponto:
                raise ValueError(f"Numero malformado: '{linha[inicio:i+1]}'")
            tem_ponto = True
            i += 1
        else:
            break
    num = linha[inicio:i]
    if not tem_digito or num.endswith('.') or num == '-':
        raise ValueError(f"Numero invalido: '{num}'")
    tokens.append(num)
    return estado_inicial, i


def estado_palavra(linha, i, tokens):
    inicio = i
    while i < len(linha) and linha[i].isalpha():
        i += 1
    # identificadores nao podem ter digito ou underscore colado
    if i < len(linha) and (linha[i].isdigit() or linha[i] == '_'):
        raise ValueError(f"Identificador invalido: '{linha[inicio:i+1]}'")
    palavra = linha[inicio:i].upper()
    tokens.append('RES' if palavra == 'RES' else palavra)
    return estado_inicial, i


def lerArquivo(nome):
    for enc in ('utf-8', 'latin-1'):
        try:
            with open(nome, encoding=enc) as f:
                linhas = [l.strip() for l in f if l.strip() and not l.strip().startswith('#')]
            return linhas
        except Exception:
            continue
    print("Erro ao abrir arquivo")
    sys.exit(1)


def salvarTokens(tokens_linhas):
    with open("tokens_saida.txt", "w", encoding="utf-8") as f:
        for linha in tokens_linhas:
            f.write(" ".join(linha) + "\n")


# essa funcao nao faz parte do compilador de verdade — uso so pra checar
# se o assembly ta gerando o resultado certo antes de testar no CPUlator
def executarExpressao(tokens_linhas):
    historico = []
    memorias = {}

    for linha in tokens_linhas:
        pilha = []
        i = 0
        while i < len(linha):
            tok = linha[i]

            if tok in ('(', ')'):
                i += 1
                continue

            if is_numero(tok):
                pilha.append(float(tok))

            elif tok in OPERADORES:
                if len(pilha) < 2:
                    raise ValueError(f"pilha insuficiente para '{tok}'")
                b, a = pilha.pop(), pilha.pop()
                if tok == '+':
                    pilha.append(a + b)
                elif tok == '-':
                    pilha.append(a - b)
                elif tok == '*':
                    pilha.append(a * b)
                elif tok == '/':
                    if b == 0:
                        raise ZeroDivisionError("divisao por zero")
                    pilha.append(a / b)
                elif tok == '//':
                    if b == 0:
                        raise ZeroDivisionError("divisao inteira por zero")
                    pilha.append(float(math.floor(a / b)))
                elif tok == '%':
                    if b == 0:
                        raise ZeroDivisionError("modulo por zero")
                    pilha.append(a - math.floor(a / b) * b)
                elif tok == '^':
                    r = 1.0
                    for _ in range(int(b)):
                        r *= a
                    pilha.append(r)

            elif tok == 'RES':
                if not pilha:
                    raise ValueError("RES sem argumento na pilha")
                n = int(pilha.pop())
                idx = max(len(historico) - n, 0)
                pilha.append(historico[idx] if historico else 0.0)

            elif is_identificador(tok):
                # se tem um valor na pilha e nao tem mais nada util depois -> escrita
                # senao -> leitura do valor guardado
                prox = next((linha[j] for j in range(i+1, len(linha))
                             if linha[j] not in ('(', ')')), None)
                if len(pilha) == 1 and prox is None:
                    memorias[tok] = pilha[-1]
                else:
                    pilha.append(memorias.get(tok, 0.0))

            i += 1

        historico.append(pilha[-1] if pilha else 0.0)

    return historico


def _coletar_memorias(tokens_linhas):
    mems = set()
    for linha in tokens_linhas:
        for t in linha:
            if is_identificador(t):
                mems.add(t)
    return mems


# helpers internos do gerador — empilha e desempilha da pilha de operandos
# a pilha fica em stack_base, indexada por R5, cada slot tem 8 bytes (double)

def _push_d0(out):
    out += [
        "  LSL R8, R5, #3",
        "  ADD R8, R4, R8",
        "  FSTD D0, [R8]",
        "  ADD R5, R5, #1",
    ]

def _pop_d0(out):
    out += [
        "  SUB R5, R5, #1",
        "  LSL R8, R5, #3",
        "  ADD R8, R4, R8",
        "  FLDD D0, [R8]",
    ]

def _pop_d1(out):
    out += [
        "  SUB R5, R5, #1",
        "  LSL R8, R5, #3",
        "  ADD R8, R4, R8",
        "  FLDD D1, [R8]",
    ]


# gera o assembly ARMv7 a partir dos tokens.
# os calculos ficam todos no assembly — nada e calculado aqui em Python
def gerarAssembly(tokens_linhas):
    out = []
    mems = _coletar_memorias(tokens_linhas)

    lo10, hi10 = double_to_ieee754(10.0)

    # secao de dados e constantes de hardware
    out += [
        ".equ HEX03,   0xFF200020",
        ".equ HEX45,   0xFF200030",
        ".equ LEDR,    0xFF200000",
        ".equ KEY,     0xFF200050",
        ".equ SW,      0xFF200040",
        ".equ DELAY_V, 2000000",
        "",
        ".data",
        "stack_base:   .space 4096",
        "resultados:   .space 4096",
        "num_results:  .word  0",
        "const_one_lo: .word  0x00000000",
        "const_one_hi: .word  0x3FF00000",
        "seg7_table:",
    ]
    for v in SEG7:
        out.append(f"  .byte {v:#04x}")
    for m in sorted(mems):
        out += [
            f"mem_{m}_lo:   .word 0",
            f"mem_{m}_hi:   .word 0",
            f"mem_{m}_init: .word 0",
        ]
    out += ["", ".text", ".global _start", ""]

    # display_result: pega D0, extrai 4 digitos decimais pra mostrar nos HEX.
    # sinal negativo aparece no HEX4, parte inteira nos LEDs vermelhos
    out += [
        "display_result:",
        "  PUSH {R0-R3, R9, R10, LR}",
        "  FMRRD R0, R1, D0",
        "  LDR R2, =0x80000000",
        "  TST R1, R2",
        "  MOV R10, #0",
        "  BEQ disp_pos",
        "  MOV R10, #1",
        "  EOR R1, R1, R2",
        "  FMDRR D0, R0, R1",
        "disp_pos:",
        "  FTOSID S2, D0",
        "  FMRS R0, S2",
        "  LDR R2, =9999",
        "  CMP R0, R2",
        "  MOVGT R0, R2",
        "  CMP R0, #0",
        "  MOVLT R0, #0",
        f"  LDR R2, ={lo10:#010x}",
        f"  LDR R3, ={hi10:#010x}",
        "  FMDRR D3, R2, R3",
        "  FMSR S4, R0",
        "  FSITOD D2, S4",
        "  LDR R9, =seg7_table",
    ]

    # extrai digito a digito por divisao: D2 / 10 -> resto = digito
    digitos = [
        ("R1", None),       # unidades — resultado fica em R1
        ("R2", 8),          # dezenas
        ("R2", 16),         # centenas
        ("R2", 24),         # milhares
    ]
    for reg, shift in digitos:
        out += [
            "  FDIVD D4, D2, D3",
            "  FTOSID S6, D4",
            "  FSITOD D4, S6",
            "  FMULD D4, D4, D3",
            "  FSUBD D4, D2, D4",
            "  FTOSID S6, D4",
            f"  FMRS {reg}, S6",
            f"  LDRB {reg}, [R9, {reg}]",
        ]
        if shift is not None:
            out.append(f"  ORR R1, R1, R2, LSL #{shift}")
        if shift != 24:
            out += [
                "  FDIVD D2, D2, D3",
                "  FTOSID S6, D2",
                "  FSITOD D2, S6",
            ]

    out += [
        "  LDR R9, =HEX03",
        "  STR R1, [R9]",
        "  LDR R9, =HEX45",
        "  CMP R10, #1",
        f"  MOVEQ R2, #{SEG_NEG:#04x}",
        "  MOVNE R2, #0x00",
        "  STR R2, [R9]",
        "  FTOSID S2, D0",
        "  FMRS R0, S2",
        "  LDR R9, =LEDR",
        "  MOV R2, #0xFF",
        "  ORR R2, R2, #0x300",
        "  AND R0, R0, R2",
        "  STR R0, [R9]",
        "  POP {R0-R3, R9, R10, LR}",
        "  BX LR",
        "",
        "delay_sub:",
        "  PUSH {R0, LR}",
        "  LDR R0, =DELAY_V",
        "delay_loop:",
        "  SUBS R0, R0, #1",
        "  BNE delay_loop",
        "  POP {R0, LR}",
        "  BX LR",
        "",
        "wait_key:",
        "  PUSH {R1, LR}",
        "  LDR R1, =KEY",
        "wk_press:",
        "  LDR R0, [R1]",
        "  AND R0, R0, #0xF",
        "  CMP R0, #0",
        "  BEQ wk_press",
        "wk_release:",
        "  LDR R1, =KEY",
        "  LDR R1, [R1]",
        "  AND R1, R1, #0xF",
        "  CMP R1, #0",
        "  BNE wk_release",
        "  POP {R1, LR}",
        "  BX LR",
        "",
    ]

    # pot_int: D0 = D0^R11, expoente inteiro positivo
    # D2 acumula o resultado (comeca em 1.0 carregado da memoria)
    out += [
        "pot_int:",
        "  PUSH {R11, LR}",
        "  LDR R0, =const_one_lo",
        "  LDR R1, =const_one_hi",
        "  LDR R0, [R0]",
        "  LDR R1, [R1]",
        "  FMDRR D2, R0, R1",
        "pot_loop:",
        "  CMP R11, #0",
        "  BEQ pot_done",
        "  FMULD D2, D2, D0",
        "  SUB R11, R11, #1",
        "  B pot_loop",
        "pot_done:",
        "  FCPYD D0, D2",
        "  POP {R11, LR}",
        "  BX LR",
        "",
        "floor_d0:",
        "  PUSH {LR}",
        "  FTOSID S4, D0",
        "  FSITOD D0, S4",
        "  POP {LR}",
        "  BX LR",
        "",
    ]

    # R4=base pilha, R5=topo, R6=vetor resultados, R7=qtd resultados salvos
    out += [
        "_start:",
        "  MRC p15, 0, R0, c1, c0, 2",
        "  ORR R0, R0, #0xF00000",
        "  MCR p15, 0, R0, c1, c0, 2",
        "  MOV R0, #0x40000000",
        "  FMXR FPEXC, R0",
        "  LDR R4, =stack_base",
        "  MOV R5, #0",
        "  LDR R6, =resultados",
        "  MOV R7, #0",
    ]

    for idx, linha in enumerate(tokens_linhas):
        out.append("  MOV R5, #0")
        i = 0
        while i < len(linha):
            tok = linha[i]

            if tok in ('(', ')'):
                i += 1
                continue

            if is_numero(tok):
                lo, hi = double_to_ieee754(tok)
                out += [
                    f"  LDR R0, ={lo:#010x}",
                    f"  LDR R1, ={hi:#010x}",
                    "  FMDRR D0, R0, R1",
                ]
                _push_d0(out)

            elif tok in OPERADORES:
                # desempilha B->D1 e A->D0
                _pop_d1(out)
                _pop_d0(out)
                if tok == '+':
                    out.append("  FADDD D0, D0, D1")
                elif tok == '-':
                    out.append("  FSUBD D0, D0, D1")
                elif tok == '*':
                    out.append("  FMULD D0, D0, D1")
                elif tok == '/':
                    out.append("  FDIVD D0, D0, D1")
                elif tok == '//':
                    out += ["  FDIVD D0, D0, D1", "  BL floor_d0"]
                elif tok == '%':
                    # D3 guarda A, depois: D0 = A - floor(A/B)*B
                    out += [
                        "  FCPYD D3, D0",
                        "  FDIVD D0, D0, D1",
                        "  BL floor_d0",
                        "  FMULD D0, D0, D1",
                        "  FSUBD D0, D3, D0",
                    ]
                elif tok == '^':
                    out += [
                        "  FTOSID S6, D1",
                        "  FMRS R11, S6",
                        "  BL pot_int",
                    ]
                _push_d0(out)

            elif tok == 'RES':
                # le N da pilha, vai buscar resultado na posicao (idx - N)
                _pop_d1(out)
                out += [
                    "  FTOSID S8, D1",
                    "  FMRS R8, S8",
                    f"  MOV R9, #{idx}",
                    "  SUB R9, R9, R8",
                    "  CMP R9, #0",
                    "  MOVLT R9, #0",
                    "  LSL R9, R9, #3",
                    "  ADD R9, R6, R9",
                    "  FLDD D0, [R9]",
                ]
                _push_d0(out)

            elif is_identificador(tok):
                prox = next((linha[j] for j in range(i+1, len(linha))
                             if linha[j] not in ('(', ')')), None)
                prev = next((linha[j] for j in range(i-1, -1, -1)
                             if linha[j] not in ('(', ')')), None)
                escrita = (prox is None and prev is not None and
                           (is_numero(prev) or prev in OPERADORES
                            or prev == 'RES' or is_identificador(prev)))
                if escrita:
                    _pop_d0(out)
                    out += [
                        "  FMRRD R0, R1, D0",
                        f"  LDR R2, =mem_{tok}_lo",
                        "  STR R0, [R2]",
                        f"  LDR R2, =mem_{tok}_hi",
                        "  STR R1, [R2]",
                        f"  LDR R2, =mem_{tok}_init",
                        "  MOV R3, #1",
                        "  STR R3, [R2]",
                    ]
                    _push_d0(out)
                else:
                    out += [
                        f"  LDR R0, =mem_{tok}_lo",
                        f"  LDR R1, =mem_{tok}_hi",
                        "  LDR R0, [R0]",
                        "  LDR R1, [R1]",
                        "  FMDRR D0, R0, R1",
                    ]
                    _push_d0(out)

            i += 1

        # fim da expressao: salva resultado no vetor e exibe no hardware
        _pop_d0(out)
        out += [
            "  LSL R8, R7, #3",
            "  ADD R8, R6, R8",
            "  FSTD D0, [R8]",
            "  ADD R7, R7, #1",
            "  LDR R9, =num_results",
            "  STR R7, [R9]",
            "  BL display_result",
            "  BL delay_sub",
            "  BL wait_key",
        ]

    # loop infinito re-exibindo todos os resultados
    out += [
        "final_loop:",
        "  LDR R9, =num_results",
        "  LDR R7, [R9]",
        "  MOV R8, #0",
        "show_loop:",
        "  LSL R0, R8, #3",
        "  ADD R0, R6, R0",
        "  FLDD D0, [R0]",
        "  BL display_result",
        "  BL wait_key",
        "  ADD R8, R8, #1",
        "  CMP R8, R7",
        "  BLT show_loop",
        "  B final_loop",
        "END: B END",
    ]

    return "\n".join(out)


def exibirResultados(resultados):
    for i, r in enumerate(resultados, 1):
        print(f"  linha {i:2d}: {r:.1f}")


def testar_afd(arquivo_passado):
    print("\n" + "=" * 70)
    print("=== TESTE DO ANALISADOR LEXICO (AFD) ===")
    print("=" * 70)

    invalidos = [
        ("(3.14.5 2.0 +)",  "numero malformado"),
        ("(3,45 2.0 -)",    "virgula como separador decimal"),
        ("(3. 2.0 *)",      "numero terminando em ponto"),
        ("(.5 2.0 /)",      "numero comecando com ponto"),
        ("(ABC123)",        "identificador com digito"),
        ("(VAR_1)",         "identificador com underscore"),
        ("(3.14 2 &)",      "operador invalido &"),
        ("(3.14 2 @)",      "operador invalido @"),
        ("(3.14 2 +",       "parentese nao fechado"),
        ("3.14 2 +)",       "parentese nao aberto"),
    ]

    print("\n--- Casos invalidos (devem ser rejeitados) ---")
    ok = 0
    for expr, motivo in invalidos:
        try:
            toks = parseExpressao(expr)
            if not validar_parenteses(toks):
                raise ValueError("parenteses desbalanceados")
            print(f"  PASSOU (deveria falhar) | {expr} [{motivo}]")
        except Exception as e:
            print(f"  rejeitado | {expr} [{motivo}] -> {e}")
            ok += 1
    print(f"  {ok}/{len(invalidos)} rejeitados corretamente")

    print(f"\n--- Linhas do arquivo {arquivo_passado} ---")
    try:
        linhas = lerArquivo(arquivo_passado)
    except Exception as e:
        print(f"nao foi possivel ler {arquivo_passado}: {e}")
        print("=" * 70)
        return

    ok = 0
    for n, linha in enumerate(linhas, 1):
        try:
            toks = parseExpressao(linha)
            if not validar_parenteses(toks):
                raise ValueError("parenteses desbalanceados")
            print(f"  linha {n:2d} | ok   | {linha}")
            ok += 1
        except Exception as e:
            print(f"  linha {n:2d} | erro | {linha} -> {e}")
    print(f"  {ok}/{len(linhas)} linhas validas")
    print("=" * 70)


def main():
    if len(sys.argv) < 2:
        print("uso: python main.py <arquivo.txt>")
        sys.exit(1)

    arquivo = sys.argv[1]
    print(f"processando: {arquivo}\n")

    linhas = lerArquivo(arquivo)
    tokens_linhas = []
    for linha in linhas:
        try:
            toks = parseExpressao(linha)
            if not validar_parenteses(toks):
                raise ValueError("parenteses desbalanceados")
            tokens_linhas.append(toks)
        except Exception as e:
            print(f"  erro lexico: '{linha}' -> {e}")

    salvarTokens(tokens_linhas)
    print(f"tokens salvos em tokens_saida.txt  ({len(tokens_linhas)} linhas validas)")

    try:
        resultados = executarExpressao(tokens_linhas)
        print("\nresultados de referencia:")
        exibirResultados(resultados)
    except Exception as e:
        print(f"  aviso: {e}")

    asm = gerarAssembly(tokens_linhas)
    with open("saida.s", "w", encoding="utf-8") as f:
        f.write(asm)
    print("\nassembly gerado em saida.s")

    testar_afd(arquivo)


if __name__ == "__main__":
    main()
