
OOC_FLAGS="-v -nolines -g +-rdynamic"

mkdir -p bin
rock ${OOC_FLAGS} -sourcepath=source herge/main -o=bin/herge

