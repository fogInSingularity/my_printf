FLAGS = -fdiagnostics-generate-patch -fdiagnostics-path-format=inline-events  \
-ggdb -std=c11 -Wall -Wextra -Waggressive-loop-optimizations                  \
-Wmissing-declarations -Wcast-align -Wcast-qual                               \
-Wchar-subscripts -Wconversion                                                \
-Wempty-body -Wfloat-equal -Wformat-nonliteral -Wformat-security              \
-Wformat-signedness -Wformat=2 -Winline -Wlogical-op                          \
-Wopenmp-simd -Wpacked -Wpointer-arith -Winit-self                            \
-Wredundant-decls -Wshadow -Wsign-conversion                                  \
-Wstrict-overflow=2 -Wsuggest-attribute=noreturn                              \
-Wsuggest-final-methods -Wsuggest-final-types                                 \
-Wswitch-default -Wswitch-enum -Wsync-nand -Wundef -Wunreachable-code         \
-Wunused -Wvariadic-macros                                                    \
-Wno-missing-field-initializers -Wno-narrowing                                \
-Wno-varargs -Wstack-protector -fcheck-new                                    \
-fstack-protector -fstrict-overflow -flto-odr-type-merging -Wstack-usage=8192

ASAN_FLAGS = -fsanitize=address,bool,bounds,enum,float-cast-overflow,$\
float-divide-by-zero,integer-divide-by-zero,leak,nonnull-attribute,null,$\
object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,$\
undefined,unreachable,vla-bound,vptr \
-fno-omit-frame-pointer

O_LEVEL = -O2

all:
	@gcc $(O_LEVEL) $(FLAGS) -c main.c -o main.o
	@nasm -f elf64 my_printf.asm -o my_printf.o
	@gcc -Wl,-z,defs -o my_printf my_printf.o main.o

san:
	@gcc $(O_LEVEL) $(ASAN_FLAGS) $(FLAGS) -c main.c -o main.o
	@nasm -f elf64 my_printf.asm -o my_printf.o
	@gcc -Wl,-z,defs -fsanitize=address -o my_printf my_printf.o main.o
#-L/lib64 -lpthread -lm

remove:
	rm my_printf.o main.o

# all:
# 	@gcc $(O_LEVEL) $(ASAN_FLAGS) $(FLAGS) -c main.c -o main.o
# 	@nasm -f elf64 my_printf.asm -o my_printf.o
# 	@nasm -f elf64 entry.asm -o entry.o
# 	@ld main.o my_printf.o entry.o -o my_printf
#-L/lib64 -lpthread -lm

# FLAGS = -Wall -Wextra -no-pie
# ASAN_FLAGS = -fsanitize=address
