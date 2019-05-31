#ifndef SYMTAB_H
#define SYMTAB_H

#define MAX_SYMBOLS 512
#define SYM_MATRIX 1
#define SYM_VALUE 2
#define SYM_CONSTANTS 3
#define SYM_LIGHT 4
#define SYM_FILE   5
#define SYM_STRING 5

#define AMBIENT_R 0
#define DIFFUSE_R 1
#define SPECULAR_R 2

struct constants
{
  double r[4];
  double g[4];
  double b[4];
  double red,green,blue;
};

struct light
{
  double l[4];
  double c[4];
};

typedef struct
{
  char *name;
  long int type;
  union{
    struct matrix *m;
    struct constants *c;
    struct light *l;
    double value;
  } s;
} SYMTAB;

extern SYMTAB symtab[MAX_SYMBOLS];
extern long int lastsym;

SYMTAB *lookup_symbol(char *name);
SYMTAB *add_symbol(char *name, long int type, void *data);
void set_value(SYMTAB *p, double value);


#endif
