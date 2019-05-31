executable = 3d
allfiles=matrix.o draw.o edgy.o prgrid.o bresenham.o manipulations.o parametric.o polygon.o polyhedra.o math.o stack.o sintable.o compiler.o lex.yy.c y.tab.c
all: $(allfiles)
	gcc -o $(executable) $(allfiles)
	./$(executable) main.mdl
	-rm *.ppm 2> /dev/null

lex.yy.c: mdl.l y.tab.h 
	flex -Id mdl.l
y.tab.c: mdl.y symtab.h parser.h
	bison -d -y mdl.y
y.tab.h: mdl.y
	bison -d -y mdl.y

draw.o: draw.S
	gcc -c -g draw.S
matrix.o: matrix.S
	gcc -c -g matrix.S
edgy.o: edgy.S
	gcc -c -g edgy.S
bresenham.o: bresenham.S
	gcc -c -g bresenham.S
prgrid.o: prgrid.S
	gcc -c -g prgrid.S
manipulations.o:manipulations.S
	gcc -c -g manipulations.S
parametric.o: parametric.S
	gcc -c -g parametric.S
polygon.o: polygon.S
	gcc -c -g polygon.S
polyhedra.o: polyhedra.S
	gcc -c -g polyhedra.S
math.o: math.S
	gcc -c -g math.S
stack.o: stack.S
	gcc -c -g stack.S
sintable.o: sintable.S
	gcc -c -g sintable.S
compiler.o: compiler.S
	gcc -c -g compiler.S
clean:
	-rm *.png *.gif *.jpg *.ppm 2> /dev/null
	-rm y.tab.c y.tab.h 2> /dev/null
	-rm lex.yy.c 2> /dev/null
	-rm -rf mdl.dSYM 2> /dev/null
	-rm y.dot 2> /dev/null
	-rm *.o 2> /dev/null
	-rm $(executable) 2> /dev/null
