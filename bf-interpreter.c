#include <stdio.h>


// Here put global variables and structs definitions

#define TAPE_LEN 30000  // Maximum tape length corresponding to the historical one

struct bf_state {
  int tape[TAPE_LEN];
  long pc;
  long ap;
  char *source_code;  // pointer to string extracted by source code file
  long source_len;  // length of source code
};

// DOING: temp function, still incomplete
bf_state read_source_code(char* file_path) {

  struct bf_state my_state; 
  // reading from file_path opening in fp
  FILE *fp;
  fp = fopen(file_path, "r");

  if (fp != NULL) {  // check that the file was opened
    //
    fseek(fp, 0, SEEK_END);
    long endf = ftell(fp); 
    fseek(fp, 0, SEEK_SET);
    long my_size = (ftell(fp) - endf);
    int *source_mem = malloc(my_size +1);
    fread(source_mem, 1, my_size, fp); 
    source_mem[my_size] = '\0';  // manually set the last byte of the buffer to '\0'
    fclose(fp);
    my_state.source_code = source_mem;
    my_state.source_len = my_size;
  }

  // I think here can be used a while pointer == EOF and read chars
  
  return NULL;  // return NULL to signal an error readin the file

}

int main(int argc, char *argv[]){

  // Check for valid arguments number as input
  if (argc != 2) {  // other count it's not expected
    printf("Usage: ./a.out <file.bf>. Used arguments %d\n", argc);
    return -1;
  }

  return 0;
}
