
OOC_FLAGS="-v -g +-rdynamic"

mkdir -p bin
rock ${OOC_FLAGS} -sourcepath=source herge/main -o=bin/herge

