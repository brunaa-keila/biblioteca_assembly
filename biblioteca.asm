.data
    filename:      .asciiz "livros.txt"  # Nome do arquivo para armazenar os livros
    menu_prompt:   .asciiz "\nMenu:\n1. Adicionar Livro\n2. Listar Livros\n3. Excluir Livro\n4. Sair\nEscolha uma op��o: "
    add_prompt:    .asciiz "Digite o nome do livro (at� 20 caracteres): "
    list_prompt:   .asciiz "Lista de Livros:\n"
    remove_prompt: .asciiz "Digite o nome do livro a ser removido: "
    book_buffer:   .space 22              # Buffer para armazenar o nome do livro + nova linha
    temp_buffer:   .space 100             # Buffer tempor�rio para leitura e escrita

.text
.globl main

main:
    li $v0, 4                      # Imprimir menu
    la $a0, menu_prompt            # Carregar endere�o da mensagem do menu
    syscall

    li $v0, 5                      # Ler op��o do usu�rio
    syscall
    move $t1, $v0                  # Armazena a op��o em $t1

    # Verifica a op��o escolhida
    beq $t1, 1, add_book           # Adicionar livro
    beq $t1, 2, list_books         # Listar livros
    beq $t1, 3, remove_book        # Excluir livro
    beq $t1, 4, exit_program       # Sair

    j main                         # Volta ao menu

# Adicionar livro
add_book:
    li $v0, 4                      # Imprimir mensagem para adicionar livro
    la $a0, add_prompt             # Carregar endere�o da mensagem de adicionar livro
    syscall

    li $v0, 8                      # Ler o nome do livro
    la $a0, book_buffer            # Buffer onde o livro ser� armazenado
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
    li $a2, 22                     # N�mero de bytes a serem escritos
    syscall

    # Fechar o arquivo
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t0                  # File descriptor
    syscall

    j main                         # Volta ao menu

# Listar livros
list_books:
    li $v0, 4                      # Imprimir mensagem de listagem
    la $a0, list_prompt            # Carregar endere�o da mensagem de listagem
    syscall

    # Abrir o arquivo para leitura
    li $v0, 13                     # Syscall para abrir arquivo
    la $a0, filename               # Nome do arquivo
    li $a1, 0                      # Abrir para leitura
    li $a2, 0                      # Modo de leitura
    syscall
    move $t0, $v0                  # File descriptor

    # Ler e imprimir o conte�do do arquivo
read_loop:
    li $v0, 14                     # Syscall para ler do arquivo
    move $a0, $t0                  # File descriptor
    la $a1, temp_buffer            # Buffer onde os dados lidos ser�o armazenados
    li $a2, 100                    # Tamanho do buffer
    syscall

    # Verificar se a leitura foi bem-sucedida
    beqz $v0, end_read             # Se n�o leu nada, sair do loop

    li $v0, 4                      # Imprimir o livro lido
    la $a0, temp_buffer            # Buffer com o nome do livro
    syscall

    j read_loop                    # Ler o pr�ximo livro

end_read:
    # Fechar o arquivo
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t0                  # File descriptor
    syscall

    j main                         # Volta ao menu

# Excluir livro
remove_book:
    li $v0, 4                      # Imprimir mensagem para remo��o
    la $a0, remove_prompt          # Carregar endere�o da mensagem de remo��o
    syscall

    li $v0, 8                      # Ler o nome do livro a ser removido
    la $a0, book_buffer            # Buffer onde o livro ser� armazenado
    li $a1, 22                     # Limitar a 21 caracteres (20 + \n)
    syscall

    # Abrir o arquivo para leitura
    li $v0, 13                     # Syscall para abrir arquivo
    la $a0, filename               # Nome do arquivo
    li $a1, 0                      # Abrir para leitura
    li $a2, 0                      # Modo de leitura
    syscall
    move $t0, $v0                  # File descriptor

    # Criar um arquivo tempor�rio para salvar os livros que n�o ser�o removidos
    li $v0, 13                     # Syscall para abrir arquivo
    la $a0, "temp.txt"             # Nome do arquivo tempor�rio
    li $a1, 1                      # Abrir para escrita
    li $a2, 0                      # Modo de leitura
    syscall
    move $t1, $v0                  # File descriptor do arquivo tempor�rio

    # Ler e escrever livros que n�o devem ser removidos
read_remove_loop:
    li $v0, 14                     # Syscall para ler do arquivo
    move $a0, $t0                  # File descriptor
    la $a1, temp_buffer            # Buffer onde os dados lidos ser�o armazenados
    li $a2, 100                    # Tamanho do buffer
    syscall

    # Verificar se a leitura foi bem-sucedida
    beqz $v0, end_remove           # Se n�o leu nada, sair do loop

    # Comparar o livro lido com o livro a ser removido
    li $t2, 0                      # �ndice para comparar
compare_loop:
    lb $t3, temp_buffer($t2)      # Carregar o caractere
    lb $t4, book_buffer($t2)      # Carregar o caractere do livro a ser removido
    beqz $t3, write_book           # Se chegar ao final do buffer, escrever
    beq $t3, $t4, skip_write       # Se forem iguais, pular a escrita

    addi $t2, $t2, 1               # Pr�ximo caractere
    j compare_loop                 # Continuar compara��o

skip_write:
    j read_remove_loop             # Pular a escrita do livro a ser removido

write_book:
    # Escrever no arquivo tempor�rio
    li $v0, 15                     # Syscall para escrever em arquivo
    move $a0, $t1                  # File descriptor do arquivo tempor�rio
    la $a1, temp_buffer            # Buffer com o nome do livro
    li $a2, 100                    # N�mero de bytes a serem escritos
    syscall

    j read_remove_loop             # Ler o pr�ximo livro

end_remove:
    # Fechar os arquivos
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t0                  # File descriptor
    syscall
    li $v0, 16                     # Syscall para fechar arquivo
    move $a0, $t1                  # File descriptor do arquivo tempor�rio
    syscall

    # Substituir o arquivo original pelo tempor�rio
    li $v0, 8                      # Syscall para renomear arquivo
    la $a0, "temp.txt"             # Nome do arquivo tempor�rio
    la $a1, filename                # Nome do arquivo original
    syscall

    j main                         # Volta ao menu

# Sair do programa
exit_program:
    li $v0, 10                     # Syscall para sair
    syscall
