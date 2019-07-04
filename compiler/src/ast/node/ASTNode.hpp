#ifndef ASTNODE_HPP
#define ASTNODE_HPP

#include <string>

#include "../AbstractSyntaxTreePack.hpp"
#include "../../code-generator/CodeGeneratorPack.hpp"

#define DATA_TYPE_NUM 11
#define NODE_TYPE_NUM 5

namespace wic
{
    class AbstractSyntaxTree;
    class ASTBodyNode;
    class CodeGenerator;

    class ASTNode
    {
    protected:
        std::string name;
        node_type node_t;
        data_type data_t;
        ASTNode* next;

        const char *type_data_str[DATA_TYPE_NUM] =
                {
                        "int",
                        "real",
                        "bool",
                        "char",
                        "void",
                        "string",
                        "array_int",
                        "array_real",
                        "array_bool",
                        "function",
                        "unknown"
                };

        const char *type_node_str[NODE_TYPE_NUM] =
                {
                        "if",
                        "while",
                        "for",
                        "scan",
                        "print"
                };

    public:
        ASTNode();
        ASTNode(std::string, node_type, data_type);
        virtual ~ASTNode();

        std::string get_node_name();
        node_type get_node_type();
        void set_node_type(node_type);
        data_type get_data_type();
        void set_data_type(data_type);

        void add_node(ASTNode*&, ASTNode*);
        ASTNode* find(unsigned int, node_type, ASTNode*);

        virtual void check_error(std::string);
        virtual cpu_registers to_code(CodeGenerator*);

        virtual void print();

        friend class AbstractSyntaxTree;
        friend class ASTBodyNode;
    };
}

#endif
