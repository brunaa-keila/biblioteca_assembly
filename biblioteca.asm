.data
    filename:      .asciiz "livros.txt"  # Nome do arquivo para armazenar os livros
    menu_prompt:   .asciiz "\nMenu:\n1. Adicionar Livro\n2. Listar Livros\n3. Excluir Livro\n4. Sair\nEscolha uma opção: "
    add_prompt:    .asciiz "Digite o nome do livro (até 20 caracteres): "
    list_prompt:   .asciiz "Lista de Livros:\n"
    remove_prompt: .asciiz "Digite o nome do livro a ser removido: "
    book_buffer:   .space 22              # Buffer para armazenar o nome do livro + nova linha
    temp_buffer:   .space 100             # Buffer temporário para leitura e escrita

.text
.globl main

main:
    li $v0, 4                      # Imprimir menu
    la $a0, menu_prompt            # Carregar endereço da mensagem do menu
    syscall

    li $v0, 5                      # Ler opção do usuário
    syscall
    move $t1, $v0                  # Armazena a opção em $t1

    # Verifica a opção escolhida
    beq $t1, 1, add_book           # Adicionar livro
    beq $t1, 2, list_books         # Listar livros
    beq $t1, 3, remove_book        # Excluir livro
    beq $t1, 4, exit_program       # Sair

    j main                         # Volta ao menu

# Adicionar livro
add_book:
    li $v0, 4                      # Imprimir mensagem para adicionar livro
    la $a0, add_prompt             # Carregar endereço da mensagem de adicionar livro
    syscall

    li $v0, 8                      # Ler o nome do livro
    la $a0, book_buffer            # Buffer onde o livro será armazenado
    li $a1, 22                     # Limitar a 21 caracteres (20 + \n)
    syscall

    # Abrir o arquivo para adicionar o livro
    li $v0, 13                     # Syscall para abrir arquivo
    la $a0, filename               # Nome do arquivo
    li $a1, 1                      # Abrir para escrita
    li $a2, 0                      # Modo de leitura
    syscall
    move $t0, $v0                  # File descriptor

    # Escrever o livro no arquivo
    li $v0, 15                     # Syscall para escrever em arquivo
    move $a0, $t0                  # File descriptor
    la $a1, book_buffer            # Buffer com o nome do livro
    li $a2, 22                     # Número de bytes a serem escritos
    syscall

    # Fechar o arquivo
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t0                  # File descriptor
    syscall

    j main                         # Volta ao menu

# Listar livros
list_books:
    li $v0, 4                      # Imprimir mensagem de listagem
    la $a0, list_prompt            # Carregar endereço da mensagem de listagem
    syscall

    # Abrir o arquivo para leitura
    li $v0, 13                     # Syscall para abrir arquivo
    la $a0, filename               # Nome do arquivo
    li $a1, 0                      # Abrir para leitura
    li $a2, 0                      # Modo de leitura
    syscall
    move $t0, $v0                  # File descriptor

    # Ler e imprimir o conteúdo do arquivo
read_loop:
    li $v0, 14                     # Syscall para ler do arquivo
    move $a0, $t0                  # File descriptor
    la $a1, temp_buffer            # Buffer onde os dados lidos serão armazenados
    li $a2, 100                    # Tamanho do buffer
    syscall

    # Verificar se a leitura foi bem-sucedida
    beqz $v0, end_read             # Se não leu nada, sair do loop

    li $v0, 4                      # Imprimir o livro lido
    la $a0, temp_buffer            # Buffer com o nome do livro
    syscall

    j read_loop                    # Ler o próximo livro

end_read:
    # Fechar o arquivo
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t0                  # File descriptor
    syscall

    j main                         # Volta ao menu

# Excluir livro
remove_book:
    li $v0, 4                      # Imprimir mensagem para remoção
    la $a0, remove_prompt          # Carregar endereço da mensagem de remoção
    syscall

    li $v0, 8                      # Ler o nome do livro a ser removido
    la $a0, book_buffer            # Buffer onde o livro será armazenado
    li $a1, 22                     # Limitar a 21 caracteres (20 + \n)
    syscall

    # Abrir o arquivo para leitura
    li $v0, 13                     # Syscall para abrir arquivo
    la $a0, filename               # Nome do arquivo
    li $a1, 0                      # Abrir para leitura
    li $a2, 0                      # Modo de leitura
    syscall
    move $t0, $v0                  # File descriptor

    # Criar um arquivo temporário para salvar os livros que não serão removidos
    li $v0, 13                     # Syscall para abrir arquivo
    la $a0, "temp.txt"             # Nome do arquivo temporário
    li $a1, 1                      # Abrir para escrita
    li $a2, 0                      # Modo de leitura
    syscall
    move $t1, $v0                  # File descriptor do arquivo temporário

    # Ler e escrever livros que não devem ser removidos
read_remove_loop:
    li $v0, 14                     # Syscall para ler do arquivo
    move $a0, $t0                  # File descriptor
    la $a1, temp_buffer            # Buffer onde os dados lidos serão armazenados
    li $a2, 100                    # Tamanho do buffer
    syscall

    # Verificar se a leitura foi bem-sucedida
    beqz $v0, end_remove           # Se não leu nada, sair do loop

    # Comparar o livro lido com o livro a ser removido
    li $t2, 0                      # Índice para comparar
compare_loop:
    lb $t3, temp_buffer($t2)      # Carregar o caractere
    lb $t4, book_buffer($t2)      # Carregar o caractere do livro a ser removido
    beqz $t3, write_book           # Se chegar ao final do buffer, escrever
    beq $t3, $t4, skip_write       # Se forem iguais, pular a escrita

    addi $t2, $t2, 1               # Próximo caractere
    j compare_loop                 # Continuar comparação

skip_write:
    j read_remove_loop             # Pular a escrita do livro a ser removido

write_book:
    # Escrever no arquivo temporário
    li $v0, 15                     # Syscall para escrever em arquivo
    move $a0, $t1                  # File descriptor do arquivo temporário
    la $a1, temp_buffer            # Buffer com o nome do livro
    li $a2, 100                    # Número de bytes a serem escritos
    syscall

    j read_remove_loop             # Ler o próximo livro

end_remove:
    # Fechar os arquivos
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t0                  # File descriptor
    syscall
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t1                  # File descriptor do arquivo temporário
    syscall

    # Substituir o arquivo original pelo temporário
    li $v0, 8                      # Syscall para renomear arquivo
    la $a0, "temp.txt"             # Nome do arquivo temporário
    la $a1, filename                # Nome do arquivo original
    syscall

    j main                         # Volta ao menu

# Sair do programa
exit_program:
    li $v0, 10                     # Syscall para sair
    syscall
