CXX = g++

CXXFLAGS = -Wall -g -O0 -std=c++11 -DTABSIZE=4
INCLUDES = -I lcpl-AST/include -I.
LFLAGS = -L lcpl-AST/build
LIBS = -llcpl-ast
SRCS = $(wildcard source/*.cpp)
OBJS = $(SRCS:.cpp=.o)
MAIN = lcpl-parser

.PHONY: clean parser

all: clean parser $(MAIN)
	@echo  LCPL Parser has been compiled

$(MAIN): $(OBJS) 
	$(CXX) -o $(MAIN) $(OBJS) lex.yy.o lcpl.tab.o $(LFLAGS) $(LIBS)

%.o:%.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $<  -o $@

parser:
	bison  -d -v lcpl.y -mmacosx-version-min=10.1
	flex lcpl.l
	$(CXX) $(CXXFLAGS) $(INCLUDES) lex.yy.c -c
	$(CXX) $(CXXFLAGS) $(INCLUDES) lcpl.tab.c -c

clean:
	$(RM) source/*.o *~ $(MAIN) lcpl.tab.* lex.yy.* lcpl.output
