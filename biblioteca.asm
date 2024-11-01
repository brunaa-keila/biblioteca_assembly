.data
    prompt_choice:  .asciiz "Escolha uma opção (1 - Adicionar, 2 - Listar, 3 - Remover, 0 - Sair): "
    prompt_add:     .asciiz "Digite o título do livro: "
    prompt_author:  .asciiz "Digite o autor do livro: "
    prompt_list:    .asciiz "Listando livros:\n"
    prompt_remove:  .asciiz "Digite o título do livro a remover: "
    buffer:         .space 128
    title_buffer:   .space 64
    author_buffer:  .space 64
    filename:       .asciiz "livros.txt"
    newline:        .asciiz "\n"

.text
.globl main

main:
    # Menu de opções
menu:
    li $v0, 4                       
    la $a0, prompt_choice
    syscall

    li $v0, 5                       
    syscall

    # Verifica se a entrada é válida
    bltz $v0, menu                  
    bgt $v0, 3, menu               

    move $t0, $v0                   

    beq $t0, 0, exit                
    beq $t0, 1, add_book           
    beq $t0, 2, list_books          
    beq $t0, 3, remove_book        
    j menu                          

add_book:
    li $v0, 4                      
    la $a0, prompt_add
    syscall

    li $v0, 8                      
    la $a0, title_buffer
    li $a1, 64
    syscall

    li $v0, 4                       
    la $a0, prompt_author
    syscall

    li $v0, 8                      
    la $a0, author_buffer
    li $a1, 64
    syscall

    # Adicionar ao arquivo
    li $v0, 13                      
    la $a0, filename
    li $a1, 1                       
    li $a2, 0                      
    syscall

    move $t1, $v0                   

    # Escrever título e autor
    li $v0, 14                     
    la $a0, title_buffer           
    li $a1, 64                      
    syscall

    # Escrever separador
    li $v0, 14                      
    la $a0, newline                 
    li $a1, 1                       
    syscall

    li $v0, 14                    
    la $a0, author_buffer          
    li $a1, 64                     
    syscall

    # Escrever nova linha
    li $v0, 14                     
    la $a0, newline                
    li $a1, 1                      
    syscall

    li $v0, 16                     
    move $a0, $t1
    syscall

    j menu

list_books:
    li $v0, 4                       
    la $a0, prompt_list
    syscall

    li $v0, 13                    
    la $a0, filename
    li $a1, 0                       
    li $a2, 0                      
    syscall

    move $t1, $v0                  

read_loop:
    li $v0, 15                     
    la $a0, buffer
    li $a1, 128                    
    syscall

    move $t2, $v0                  

    # Se não leu nada, sair
    beqz $t2, close_list

    # Imprimir conteúdo lido
    li $v0, 4                       
    la $a0, buffer
    li $a1, $t2                     
    syscall

    # Imprimir nova linha
    li $v0, 4                       
    la $a0, newline                
    li $a1, 1                       
    syscall

    j read_loop                    

close_list:
    li $v0, 16                      
    move $a0, $t1
    syscall

    j menu

remove_book:
    li $v0, 4                      
    la $a0, prompt_remove
    syscall

    li $v0, 8                       
    la $a0, title_buffer
    li $a1, 64
    syscall

    # Criar novo arquivo temporário
    li $v0, 13                      
    la $a0, "temp.txt"
    li $a1, 8                      
    li $a2, 0                      
    syscall

    move $t2, $v0                   

    # Abrir o arquivo original para leitura
    li $v0, 13                      
    la $a0, filename
    li $a1, 0                      
    li $a2, 0                      
    syscall

    move $t1, $v0                  

read_remove_loop:
    li $v0, 15                      
    la $a0, buffer
    li $a1, 128                     
    syscall

    move $t3, $v0                   

    # Se não leu nada, fechar arquivos
    beqz $t3, close_remove

    # Comparar título
    li $t4, 0                       
compare_loop:
    lb $t5, title_buffer($t4)      
    lb $t6, buffer($t4)            

    beqz $t5, write_line            

    # Verifica se a linha atual contém o título a ser removido
    beq $t5, $t6, compare_loop     

    # Se o título não for igual, escrever no arquivo temporário
    li $v0, 14                     
    la $a0, buffer
    li $a1, 128                    
    syscall

write_line:
    # Escrever nova linha
    li $v0, 14                     
    la $a0, newline                 
    li $a1, 1                     
    syscall

    j read_remove_loop            

close_remove:
    li $v0, 16                    
    move $a0, $t1
    syscall

    li $v0, 16                     
    move $a0, $t2
    syscall

    # Substituir arquivo original pelo temporário
    li $v0, 15                    
    la $a0, "temp.txt"
    la $a1, filename
    syscall

    j menu

exit:
    li $v0, 10                     
    syscall
