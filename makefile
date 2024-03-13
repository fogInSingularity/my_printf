CC = gcc

FLAGS = -ggdb -std=c11 -Wall -Wextra                  \
-Wmissing-declarations -Wcast-align -Wcast-qual                               \
-Wchar-subscripts -Wconversion                                                \
-Wempty-body -Wfloat-equal -Wformat-nonliteral -Wformat-security              \
-Wformat=2 -Winline                       \
-Wpacked -Wpointer-arith -Winit-self                            \
-Wredundant-decls -Wshadow -Wsign-conversion                                  \
-Wstrict-overflow=2                               \
-Wswitch-default -Wswitch-enum  -Wundef -Wunreachable-code         \
-Wunused -Wvariadic-macros                                                    \
-Wno-missing-field-initializers -Wno-narrowing                                \
-Wno-varargs -Wstack-protector -fcheck-new                                    \
-fstack-protector -fstrict-overflow

# -fdiagnostics-generate-patch -fdiagnostics-path-format=inline-events -flto-odr-type-merging
# -Waggressive-loop-optimizations -Wformat-signedness -Wlogical-op -Wsuggest-final-types -Wsuggest-final-methods
# -Wopenmp-simd -Wsync-nand -Wsuggest-attribute=noreturn

ASAN_FLAGS = -fsanitize=address,bool,bounds,enum,float-cast-overflow,$\
float-divide-by-zero,integer-divide-by-zero,leak,nonnull-attribute,null,$\
object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,$\
undefined,unreachable,vla-bound,vptr \
-fno-omit-frame-pointer

O_LEVEL_DEBUG = -Og
O_LEVEL_RELEASE = -O2

LIB =

all:
	@$(CC) $(O_LEVEL_DEBUG) $(FLAGS) $(ASAN_FLAGS) $(LIB) -c main.c -o main.o
	@nasm -Werror -f elf64 my_printf.asm -o my_printf.o
	@$(CC) $(ASAN_FLAGS) $(LIB) -o my_printf my_printf.o main.o
# -Wl,-z,defs
release:
	@$(CC) $(O_LEVEL_RELEASE) $(FLAGS) -c main.c -o main.o
	@nasm -Werror -f elf64 my_printf.asm -o my_printf.o
	@$(CC) -o my_printf my_printf.o main.o
#-L/lib64 -lpthread -lm
#-Wl,-z,defs

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
