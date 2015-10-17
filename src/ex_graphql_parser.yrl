Nonterminals
  Document
  Definitions Definition OperationDefinition FragmentDefinition TypeDefinition
  ObjectTypeDefinition InterfaceTypeDefinition UnionTypeDefinition
  ScalarTypeDefinition EnumTypeDefinition InputObjectTypeDefinition TypeExtensionDefinition
  FieldDefinitionList FieldDefinition ImplementsInterfaces ArgumentsDefinition
  InputValueDefinitionList InputValueDefinition UnionMembers
  EnumValueDefinitionList EnumValueDefinition
  SelectionSet Selections Selection
  OperationType Name NameWithoutOn VariableDefinitions VariableDefinition Directives Directive
  Field Alias Arguments ArgumentList Argument
  FragmentSpread FragmentName InlineFragment
  VariableDefinitionList Variable DefaultValue
  Type TypeCondition NamedTypeList NamedType ListType NonNullType
  Value EnumValue ListValue Values ObjectValue ObjectFields ObjectField.

Terminals
  '{' '}' '(' ')' '[' ']' '!' ':' '@' '$' '=' '|' '...'
  'query' 'mutation' 'fragment' 'on' 'null'
  'type' 'implements' 'interface' 'union' 'scalar' 'enum' 'input' 'extend'
  name int_value float_value string_value boolean_value.

Rootsymbol Document.

Document -> Definitions : build_ast_node('Document', #{'definitions' => '$1'}).

Definitions -> Definition : ['$1'].
Definitions -> Definition Definitions : ['$1'|'$2'].

Definition -> OperationDefinition : '$1'.
Definition -> FragmentDefinition : '$1'.
Definition -> TypeDefinition : '$1'.

OperationType -> 'query' : extract_atom('$1').
OperationType -> 'mutation' : extract_atom('$1').

OperationDefinition -> SelectionSet : build_ast_node('OperationDefinition', #{'operation' => 'query', 'selectionSet' => '$1'}).
OperationDefinition -> OperationType Name SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => '$2', 'selectionSet' => '$3'}).
OperationDefinition -> OperationType Name VariableDefinitions SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => '$2', 'variableDefinitions' => '$3', 'selectionSet' => '$4'}).
OperationDefinition -> OperationType Name Directives SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => '$2', 'directives' => '$3', 'selectionSet' => '$4'}).
OperationDefinition -> OperationType Name VariableDefinitions Directives SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => '$2', 'variableDefinitions' => '$3', 'directives' => '$4', 'selectionSet' => '$5'}).

FragmentDefinition -> 'fragment' FragmentName 'on' TypeCondition SelectionSet : build_ast_node('FragmentDefinition', #{'name' => '$2', 'typeCondition' => '$4', 'selectionSet' => '$5'}).
FragmentDefinition -> 'fragment' FragmentName 'on' TypeCondition Directives SelectionSet : build_ast_node('FragmentDefinition', #{'name' => '$2', 'typeCondition' => '$4', 'directives' => '$5', 'selectionSet' => '$6'}).

TypeCondition -> NamedType : '$1'.

VariableDefinitions -> '(' VariableDefinitionList ')' : '$2'.
VariableDefinitionList -> VariableDefinition : ['$1'].
VariableDefinitionList -> VariableDefinition VariableDefinitionList : ['$1'|'$2'].
VariableDefinition -> Variable ':' Type : build_ast_node('VariableDefinition', #{'variable' => '$1', 'type' => '$3'}).
VariableDefinition -> Variable ':' Type DefaultValue : build_ast_node('VariableDefinition', #{'variable' => '$1', 'type' => '$3', 'defaultValue' => '$4'}).
Variable -> '$' Name : build_ast_node('Variable', #{'name' => '$2'}).

DefaultValue -> '=' Value : '$2'.

Type -> NamedType : '$1'.
Type -> ListType : '$1'.
Type -> NonNullType : '$1'.
NamedType -> Name : build_ast_node('NamedType', #{'name' => '$1'}).
ListType -> '[' Type ']' : build_ast_node('ListType', #{'type' => '$2'}).
NonNullType -> NamedType '!' : build_ast_node('NonNullType', #{'type' => '$1'}).
NonNullType -> ListType '!' : build_ast_node('NonNullType', #{'type' => '$1'}).

SelectionSet -> '{' Selections '}' : build_ast_node('SelectionSet', #{'selections' => '$2'}).

Selections -> Selection : ['$1'].
Selections -> Selection Selections : ['$1'|'$2'].

Selection -> Field : '$1'.
Selection -> FragmentSpread : '$1'.
Selection -> InlineFragment : '$1'.

FragmentSpread -> '...' FragmentName : build_ast_node('FragmentSpread', #{'name' => '$2'}).
FragmentSpread -> '...' FragmentName Directives : build_ast_node('FragmentSpread', #{'name' => '$2', 'directives' => '$3'}).

InlineFragment -> '...' 'on' TypeCondition SelectionSet : build_ast_node('InlineFragment', #{'typeCondition' => '$3', 'selectionSet' => '$4'}).
InlineFragment -> '...' 'on' TypeCondition Directives SelectionSet : build_ast_node('InlineFragment', #{'typeCondition' => '$3', 'directives' => '$4', 'selectionSet' => '$5'}).

FragmentName -> NameWithoutOn : '$1'.

Field -> Name : build_ast_node('Field', #{'name' => '$1'}).
Field -> Name Arguments : build_ast_node('Field', #{'name' => '$1', 'arguments' => '$2'}).
Field -> Name Directives : build_ast_node('Field', #{'name' => '$1', 'directives' => '$2'}).
Field -> Name SelectionSet : build_ast_node('Field', #{'name' => '$1', 'selectionSet' => '$2'}).
Field -> Name Directives SelectionSet : build_ast_node('Field', #{'name' => '$1', 'directives' => '$2', 'selectionSet' => '$3'}).
Field -> Name Arguments SelectionSet : build_ast_node('Field', #{'name' => '$1', 'arguments' => '$2', 'selectionSet' => '$3'}).
Field -> Name Arguments Directives : build_ast_node('Field', #{'name' => '$1', 'arguments' => '$2', 'directives' => '$3'}).
Field -> Name Arguments Directives SelectionSet : build_ast_node('Field', #{'name' => '$1', 'arguments' => '$2', 'directives' => '$3', 'selectionSet' => '$4'}).
Field -> Alias Name : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2'}).
Field -> Alias Name Arguments : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2', 'arguments' => '$3'}).
Field -> Alias Name SelectionSet : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2', 'selectionSet' => '$3'}).
Field -> Alias Name Arguments SelectionSet : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2', 'arguments' => '$3', 'selectionSet' => '$4'}).
Field -> Alias Name Directives : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2', 'directives' => '$3'}).
Field -> Alias Name Arguments Directives : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2', 'arguments' => '$3', 'directives' => '$4'}).
Field -> Alias Name Directives SelectionSet : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2', 'directives' => '$3', 'selectionSet' => '$4'}).
Field -> Alias Name Arguments Directives SelectionSet : build_ast_node('Field', #{'alias' => '$1', 'name' => '$2', 'arguments' => '$3', 'directives' => '$4', 'selectionSet' => '$5'}).

Alias -> Name ':' : '$1'.

Arguments -> '(' ArgumentList ')' : '$2'.
ArgumentList -> Argument : ['$1'].
ArgumentList -> Argument ArgumentList : ['$1'|'$2'].
Argument -> Name ':' Value : build_ast_node('Argument', #{name => '$1', value => '$3'}).

Directives -> Directive : ['$1'].
Directives -> Directive Directives : ['$1'|'$2'].
Directive -> '@' Name : build_ast_node('Directive', #{name => '$2'}).
Directive -> '@' Name Arguments : build_ast_node('Directive', #{name => '$2', 'arguments' => '$3'}).

NameWithoutOn -> name : extract_token('$1').
NameWithoutOn -> 'query' : extract_keyword('$1').
NameWithoutOn -> 'mutation' : extract_keyword('$1').
NameWithoutOn -> 'fragment' : extract_keyword('$1').
NameWithoutOn -> 'type' : extract_keyword('$1').
NameWithoutOn -> 'implements' : extract_keyword('$1').
NameWithoutOn -> 'interface' : extract_keyword('$1').
NameWithoutOn -> 'union' : extract_keyword('$1').
NameWithoutOn -> 'scalar' : extract_keyword('$1').
NameWithoutOn -> 'enum' : extract_keyword('$1').
NameWithoutOn -> 'input' : extract_keyword('$1').
NameWithoutOn -> 'extend' : extract_keyword('$1').
NameWithoutOn -> 'null' : extract_keyword('$1').

Name -> NameWithoutOn : '$1'.
Name -> 'on' : extract_keyword('$1').

Value -> Variable : '$1'.
Value -> int_value : build_ast_node('IntValue', #{'value' => extract_integer('$1')}).
Value -> float_value : build_ast_node('FloatValue', #{'value' => extract_float('$1')}).
Value -> string_value : build_ast_node('StringValue', #{'value' => extract_quoted_string_token('$1')}).
Value -> boolean_value : build_ast_node('BooleanValue', #{'value' => extract_boolean('$1')}).
Value -> EnumValue : build_ast_node('EnumValue', #{'value' => '$1'}).
Value -> ListValue : build_ast_node('ListValue', #{'values' => '$1'}).
Value -> ObjectValue : build_ast_node('ObjectValue', #{'fields' => '$1'}).

EnumValue -> Name : '$1'.

ListValue -> '[' ']' : [].
ListValue -> '[' Values ']' : '$2'.
Values -> Value : ['$1'].
Values -> Value Values : ['$1'|'$2'].

ObjectValue -> '{' '}' : [].
ObjectValue -> '{' ObjectFields '}' : '$2'.
ObjectFields -> ObjectField : ['$1'].
ObjectFields -> ObjectField ObjectFields : ['$1'|'$2'].
ObjectField -> Name ':' Value : build_ast_node('ObjectField', #{'name' => '$1', 'value' => '$3'}).

TypeDefinition -> ObjectTypeDefinition : '$1'.
TypeDefinition -> InterfaceTypeDefinition : '$1'.
TypeDefinition -> UnionTypeDefinition : '$1'.
TypeDefinition -> ScalarTypeDefinition : '$1'.
TypeDefinition -> EnumTypeDefinition : '$1'.
TypeDefinition -> InputObjectTypeDefinition : '$1'.
TypeDefinition -> TypeExtensionDefinition : '$1'.

ObjectTypeDefinition -> 'type' Name '{' FieldDefinitionList '}' :
  build_ast_node('ObjectTypeDefinition', #{'name' => '$2', 'fields' => '$4'}).
ObjectTypeDefinition -> 'type' Name ImplementsInterfaces '{' FieldDefinitionList '}' :
  build_ast_node('ObjectTypeDefinition', #{'name' => '$2', 'interfaces' => '$3', 'fields' => '$5'}).

ImplementsInterfaces -> 'implements' NamedTypeList : '$2'.

NamedTypeList -> NamedType : ['$1'].
NamedTypeList -> NamedType NamedTypeList : ['$1'|'$2'].

FieldDefinitionList -> FieldDefinition : ['$1'].
FieldDefinitionList -> FieldDefinition FieldDefinitionList : ['$1'|'$2'].
FieldDefinition -> Name ':' Type : build_ast_node('FieldDefinition', #{'name' => '$1', 'type' => '$3'}).
FieldDefinition -> Name ArgumentsDefinition ':' Type : build_ast_node('FieldDefinition', #{'name' => '$1', 'arguments' => '$2', 'type' => '$4'}).

ArgumentsDefinition -> '(' InputValueDefinitionList ')' : '$2'.

InputValueDefinitionList -> InputValueDefinition : ['$1'].
InputValueDefinitionList -> InputValueDefinition InputValueDefinitionList : ['$1'|'$2'].

InputValueDefinition -> Name ':' Type : build_ast_node('InputValueDefinition', #{'name' => '$1', 'type' => '$3'}).
InputValueDefinition -> Name ':' Type DefaultValue : build_ast_node('InputValueDefinition', #{'name' => '$1', 'type' => '$3', 'defaultValue' => '$4'}).

InterfaceTypeDefinition -> 'interface' Name '{' FieldDefinitionList '}' :
  build_ast_node('InterfaceTypeDefinition', #{'name' => '$2', 'fields' => '$4'}).

UnionTypeDefinition -> 'union' Name '=' UnionMembers :
  build_ast_node('UnionTypeDefinition', #{'name' => '$2', 'types' => '$4'}).

UnionMembers -> NamedType : ['$1'].
UnionMembers -> NamedType '|' UnionMembers : ['$1'|'$3'].

ScalarTypeDefinition -> 'scalar' Name : build_ast_node('ScalarTypeDefinition', #{'name' => '$2'}).

EnumTypeDefinition -> 'enum' Name '{' EnumValueDefinitionList '}':
  build_ast_node('EnumTypeDefinition', #{'name' => '$2', 'values' => '$4'}).

EnumValueDefinitionList -> EnumValueDefinition : ['$1'].
EnumValueDefinitionList -> EnumValueDefinition EnumValueDefinitionList : ['$1'|'$2'].

EnumValueDefinition -> EnumValue : '$1'.

InputObjectTypeDefinition -> 'input' Name '{' InputValueDefinitionList '}' :
  build_ast_node('InputObjectTypeDefinition', #{'name' => '$2', 'fields' => '$4'}).

TypeExtensionDefinition -> 'extend' ObjectTypeDefinition :
  build_ast_node('TypeExtensionDefinition', #{'definition' => '$2'}).

Erlang code.

extract_atom({Value, _Line}) -> Value.
extract_token({_Token, _Line, Value}) -> list_to_binary(Value).
extract_quoted_string_token({_Token, _Line, Value}) -> list_to_binary(lists:sublist(Value, 2, length(Value) - 2)).
extract_integer({_Token, _Line, Value}) ->
  {Int, []} = string:to_integer(Value), Int.
extract_float({_Token, _Line, Value}) ->
  {Float, []} = string:to_float(Value), Float.
extract_boolean({_Token, _Line, "true"}) -> true;
extract_boolean({_Token, _Line, "false"}) -> false.
extract_keyword({Value, _Line}) -> list_to_binary(atom_to_list(Value)).

build_ast_node(Type, Node) ->
  Node#{'__struct__' => list_to_atom("Elixir.ExGraphQL.AST." ++ atom_to_list(Type)), source_location => #{start => 0}}.
