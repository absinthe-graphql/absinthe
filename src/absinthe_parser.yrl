Nonterminals
  Document
  Definitions Definition OperationDefinition Fragment TypeDefinition
  ObjectTypeDefinition InterfaceTypeDefinition UnionTypeDefinition
  ScalarTypeDefinition EnumTypeDefinition InputObjectTypeDefinition TypeExtensionDefinition
  FieldDefinitionList FieldDefinition ImplementsInterfaces ArgumentsDefinition
  InputValueDefinitionList InputValueDefinition UnionMembers
  EnumValueDefinitionList EnumValueDefinition
  DirectiveDefinition DirectiveDefinitionLocations
  SelectionSet Selections Selection
  OperationType Name NameWithoutOn VariableDefinitions VariableDefinition Directives Directive
  Field Alias Arguments ArgumentList Argument
  FragmentSpread FragmentName InlineFragment
  VariableDefinitionList Variable DefaultValue
  Type TypeCondition NamedTypeList NamedType ListType NonNullType
  Value EnumValue ListValue Values ObjectValue ObjectFields ObjectField SchemaDefinition.

Terminals
  '{' '}' '(' ')' '[' ']' '!' ':' '@' '$' '=' '|' '...'
  'query' 'mutation' 'subscription' 'fragment' 'on' 'directive'
  'type' 'implements' 'interface' 'union' 'scalar' 'enum' 'input' 'extend' 'schema'
  name int_value float_value string_value block_string_value boolean_value null.

Rootsymbol Document.

Document -> Definitions : build_ast_node('Document', #{'definitions' => '$1'}, #{'start_line' => extract_line('$1')}).

Definitions -> Definition : ['$1'].
Definitions -> Definition Definitions : ['$1'|'$2'].

Definition -> OperationDefinition : '$1'.
Definition -> Fragment : '$1'.
Definition -> TypeDefinition : '$1'.

OperationType -> 'query' : extract_atom('$1').
OperationType -> 'mutation' : extract_atom('$1').
OperationType -> 'subscription' : extract_atom('$1').

OperationDefinition -> SelectionSet : build_ast_node('OperationDefinition', #{'operation' => 'query', 'selection_set' => '$1'}, #{'start_line' => extract_child_line('$1')}).
OperationDefinition -> OperationType SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'selection_set' => '$2'}, #{'start_line' => extract_line('$2')}).
OperationDefinition -> OperationType VariableDefinitions SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'variable_definitions' => '$2', 'selection_set' => '$3'}, #{'start_line' => extract_child_line('$2')}).
OperationDefinition -> OperationType VariableDefinitions Directives SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'variable_definitions' => '$2', 'directives' => '$3', 'selection_set' => '$4'}, #{'start_line' => extract_child_line('$2')}).
OperationDefinition -> OperationType Name SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => extract_binary('$2'), 'selection_set' => '$3'}, #{'start_line' => extract_line('$2')}).
OperationDefinition -> OperationType Name VariableDefinitions SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => extract_binary('$2'), 'variable_definitions' => '$3', 'selection_set' => '$4'}, #{'start_line' => extract_line('$2')}).
OperationDefinition -> OperationType Name Directives SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => extract_binary('$2'), 'directives' => '$3', 'selection_set' => '$4'}, #{'start_line' => extract_line('$2')}).
OperationDefinition -> OperationType Name VariableDefinitions Directives SelectionSet : build_ast_node('OperationDefinition', #{'operation' => '$1', 'name' => extract_binary('$2'), 'variable_definitions' => '$3', 'directives' => '$4', 'selection_set' => '$5'}, #{'start_line' => extract_line('$2')}).

Fragment -> 'fragment' FragmentName 'on' TypeCondition SelectionSet : build_ast_node('Fragment', #{'name' => '$2', 'type_condition' => '$4', 'selection_set' => '$5'}, #{'start_line' => extract_line('$1')}).
Fragment -> 'fragment' FragmentName 'on' TypeCondition Directives SelectionSet : build_ast_node('Fragment', #{'name' => '$2', 'type_condition' => '$4', 'directives' => '$5', 'selection_set' => '$6'}, #{'start_line' => extract_line('$1')}).

TypeCondition -> NamedType : '$1'.

VariableDefinitions -> '(' VariableDefinitionList ')' : '$2'.
VariableDefinitionList -> VariableDefinition : ['$1'].
VariableDefinitionList -> VariableDefinition VariableDefinitionList : ['$1'|'$2'].
VariableDefinition -> Variable ':' Type : build_ast_node('VariableDefinition', #{'variable' => '$1', 'type' => '$3'}, #{'start_line' => extract_child_line('$1')}).
VariableDefinition -> Variable ':' Type DefaultValue : build_ast_node('VariableDefinition', #{'variable' => '$1', 'type' => '$3', 'default_value' => '$4'}, #{'start_line' => extract_child_line('$1')}).
Variable -> '$' NameWithoutOn : build_ast_node('Variable', #{'name' => extract_binary('$2')}, #{'start_line' => extract_line('$1')}).
Variable -> '$' 'on' : build_ast_node('Variable', #{'name' => extract_binary('$2')}, #{'start_line' => extract_line('$1')}).

DefaultValue -> '=' Value : '$2'.

Type -> NamedType : '$1'.
Type -> ListType : '$1'.
Type -> NonNullType : '$1'.
NamedType -> Name : build_ast_node('NamedType', #{'name' => extract_binary('$1')}, #{'start_line' => extract_line('$1')}).
ListType -> '[' Type ']' : build_ast_node('ListType', #{'type' => '$2'}, #{'start_line' => extract_line('$1')}).
NonNullType -> NamedType '!' : build_ast_node('NonNullType', #{'type' => '$1'}, #{'start_line' => extract_line('$1')}).
NonNullType -> ListType '!' : build_ast_node('NonNullType', #{'type' => '$1'}, #{'start_line' => extract_line('$1')}).

SelectionSet -> '{' Selections '}' : build_ast_node('SelectionSet', #{'selections' => '$2'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$3')}).

Selections -> Selection : ['$1'].
Selections -> Selection Selections : ['$1'|'$2'].

Selection -> Field : '$1'.
Selection -> FragmentSpread : '$1'.
Selection -> InlineFragment : '$1'.

FragmentSpread -> '...' FragmentName : build_ast_node('FragmentSpread', #{'name' => '$2'}, #{'start_line' => extract_line('$1')}).
FragmentSpread -> '...' FragmentName Directives : build_ast_node('FragmentSpread', #{'name' => '$2', 'directives' => '$3'}, #{'start_line' => extract_line('$1')}).

InlineFragment -> '...' 'on' TypeCondition SelectionSet : build_ast_node('InlineFragment', #{'type_condition' => '$3', 'selection_set' => '$4'}, #{'start_line' => extract_line('$1')}).
InlineFragment -> '...' 'on' TypeCondition Directives SelectionSet : build_ast_node('InlineFragment', #{'type_condition' => '$3', 'directives' => '$4', 'selection_set' => '$5'}, #{'start_line' => extract_line('$1')}).
InlineFragment -> '...' Directives SelectionSet : build_ast_node('InlineFragment', #{'directives' => '$2', 'selection_set' => '$3'}, #{'start_line' => extract_line('$1')}).
InlineFragment -> '...' SelectionSet : build_ast_node('InlineFragment', #{'selection_set' => '$2'}, #{'start_line' => extract_line('$1')}).

FragmentName -> NameWithoutOn : extract_binary('$1').

Field -> Name : build_ast_node('Field', #{'name' => extract_binary('$1')}, #{'start_line' => extract_line('$1')}).
Field -> Name Arguments : build_ast_node('Field', #{'name' => extract_binary('$1'), 'arguments' => '$2'}, #{'start_line' => extract_line('$1')}).
Field -> Name Directives : build_ast_node('Field', #{'name' => extract_binary('$1'), 'directives' => '$2'}, #{'start_line' => extract_line('$1')}).
Field -> Name SelectionSet : build_ast_node('Field', #{'name' => extract_binary('$1'), 'selection_set' => '$2'}, #{'start_line' => extract_line('$1')}).
Field -> Name Directives SelectionSet : build_ast_node('Field', #{'name' => extract_binary('$1'), 'directives' => '$2', 'selection_set' => '$3'}, #{'start_line' => extract_line('$1')}).
Field -> Name Arguments SelectionSet : build_ast_node('Field', #{'name' => extract_binary('$1'), 'arguments' => '$2', 'selection_set' => '$3'}, #{'start_line' => extract_line('$1')}).
Field -> Name Arguments Directives : build_ast_node('Field', #{'name' => extract_binary('$1'), 'arguments' => '$2', 'directives' => '$3'}, #{'start_line' => extract_line('$1')}).
Field -> Name Arguments Directives SelectionSet : build_ast_node('Field', #{'name' => extract_binary('$1'), 'arguments' => '$2', 'directives' => '$3', 'selection_set' => '$4'}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2')}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name Arguments : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2'), 'arguments' => '$3'}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name SelectionSet : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2'), 'selection_set' => '$3'}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name Arguments SelectionSet : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2'), 'arguments' => '$3', 'selection_set' => '$4'}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name Directives : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2'), 'directives' => '$3'}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name Arguments Directives : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2'), 'arguments' => '$3', 'directives' => '$4'}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name Directives SelectionSet : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2'), 'directives' => '$3', 'selection_set' => '$4'}, #{'start_line' => extract_line('$1')}).
Field -> Alias Name Arguments Directives SelectionSet : build_ast_node('Field', #{'alias' => extract_binary('$1'), 'name' => extract_binary('$2'), 'arguments' => '$3', 'directives' => '$4', 'selection_set' => '$5'}, #{'start_line' => extract_line('$1')}).

Alias -> Name ':' : '$1'.

Arguments -> '(' ArgumentList ')' : '$2'.
ArgumentList -> Argument : ['$1'].
ArgumentList -> Argument ArgumentList : ['$1'|'$2'].
Argument -> NameWithoutOn ':' Value : build_ast_node('Argument', #{name => extract_binary('$1'), value => '$3'}, #{'start_line' => extract_line('$1')}).
Argument -> 'on' ':' Value : build_ast_node('Argument', #{name => extract_binary('$1'), value => '$3'}, #{'start_line' => extract_line('$1')}).

Directives -> Directive : ['$1'].
Directives -> Directive Directives : ['$1'|'$2'].
Directive -> '@' NameWithoutOn : build_ast_node('Directive', #{name => extract_binary('$2')}, #{'start_line' => extract_line('$1')}).
Directive -> '@' NameWithoutOn Arguments : build_ast_node('Directive', #{name => extract_binary('$2'), 'arguments' => '$3'}, #{'start_line' => extract_line('$1')}).
Directive -> '@' 'on' : build_ast_node('Directive', #{name => extract_binary('$2')}, #{'start_line' => extract_line('$1')}).
Directive -> '@' 'on' Arguments : build_ast_node('Directive', #{name => extract_binary('$2'), 'arguments' => '$3'}, #{'start_line' => extract_line('$1')}).

NameWithoutOn -> 'name' : '$1'.
NameWithoutOn -> 'query' : extract_binary('$1').
NameWithoutOn -> 'mutation' : extract_binary('$1').
NameWithoutOn -> 'subscription' : extract_binary('$1').
NameWithoutOn -> 'fragment' : extract_binary('$1').
NameWithoutOn -> 'type' : extract_binary('$1').
NameWithoutOn -> 'implements' : extract_binary('$1').
NameWithoutOn -> 'interface' : extract_binary('$1').
NameWithoutOn -> 'union' : extract_binary('$1').
NameWithoutOn -> 'scalar' : extract_binary('$1').
NameWithoutOn -> 'schema' : extract_binary('$1').
NameWithoutOn -> 'enum' : extract_binary('$1').
NameWithoutOn -> 'input' : extract_binary('$1').
NameWithoutOn -> 'extend' : extract_binary('$1').
NameWithoutOn -> 'directive' : extract_binary('$1').

Name -> NameWithoutOn : '$1'.
Name -> 'on' : extract_binary('$1').

Value -> Variable : '$1'.
Value -> int_value :     build_ast_node('IntValue',     #{'value' => extract_integer('$1')},             #{'start_line' => extract_line('$1')}).
Value -> float_value :   build_ast_node('FloatValue',   #{'value' => extract_float('$1')},               #{'start_line' => extract_line('$1')}).
Value -> block_string_value :  build_ast_node('StringValue',  #{'value' => extract_quoted_block_string_token('$1')}, #{'start_line' => extract_line('$1')}).
Value -> string_value :  build_ast_node('StringValue',  #{'value' => extract_quoted_string_token('$1')}, #{'start_line' => extract_line('$1')}).
Value -> boolean_value : build_ast_node('BooleanValue', #{'value' => extract_boolean('$1')},             #{'start_line' => extract_line('$1')}).
Value -> null :          build_ast_node('NullValue',    #{},                 #{'start_line' => extract_line('$1')}).
Value -> EnumValue :     build_ast_node('EnumValue',    #{'value' => '$1'},  #{'start_line' => extract_line('$1')}).
Value -> ListValue :     build_ast_node('ListValue',    #{'values' => '$1'}, #{'start_line' => extract_child_line('$1')}).
Value -> ObjectValue :   build_ast_node('ObjectValue',  #{'fields' => '$1'}, #{'start_line' => extract_child_line('$1')}).


EnumValue -> Name : extract_binary('$1').

ListValue -> '[' ']' : [].
ListValue -> '[' Values ']' : '$2'.
Values -> Value : ['$1'].
Values -> Value Values : ['$1'|'$2'].

ObjectValue -> '{' '}' : [].
ObjectValue -> '{' ObjectFields '}' : '$2'.
ObjectFields -> ObjectField : ['$1'].
ObjectFields -> ObjectField ObjectFields : ['$1'|'$2'].
ObjectField -> Name ':' Value : build_ast_node('ObjectField', #{'name' => extract_binary('$1'), 'value' => '$3'}, #{'start_line' => extract_line('$1')}).

TypeDefinition -> SchemaDefinition : '$1'.
TypeDefinition -> ObjectTypeDefinition : '$1'.
TypeDefinition -> InterfaceTypeDefinition : '$1'.
TypeDefinition -> UnionTypeDefinition : '$1'.
TypeDefinition -> ScalarTypeDefinition : '$1'.
TypeDefinition -> EnumTypeDefinition : '$1'.
TypeDefinition -> InputObjectTypeDefinition : '$1'.
TypeDefinition -> TypeExtensionDefinition : '$1'.
TypeDefinition -> DirectiveDefinition : '$1'.

DirectiveDefinition -> 'directive' '@' Name 'on' DirectiveDefinitionLocations :
  build_ast_node('DirectiveDefinition', #{'name' => extract_binary('$3'), 'locations' =>'$5'}, #{'start_line' => extract_line('$1')}).
DirectiveDefinition -> 'directive' '@' Name ArgumentsDefinition 'on' DirectiveDefinitionLocations :
  build_ast_node('DirectiveDefinition', #{'name' => extract_binary('$3'), 'arguments' => '$4', 'locations' =>'$6'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$1')}).

DirectiveDefinition -> 'directive' '@' Name 'on' DirectiveDefinitionLocations Directives :
  build_ast_node('DirectiveDefinition', #{'name' => extract_binary('$3'), 'directives' => '$6', 'locations' => '$5'}, #{'start_line' => extract_line('$1')}).
DirectiveDefinition -> 'directive' '@' Name ArgumentsDefinition 'on' DirectiveDefinitionLocations Directives :
  build_ast_node('DirectiveDefinition', #{'name' => extract_binary('$3'), 'arguments' => '$4', 'directives' => '$7', 'locations' =>'$6'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$1')}).

SchemaDefinition -> 'schema' '{' FieldDefinitionList '}' : build_ast_node('SchemaDefinition', #{'fields' => '$3'}, #{'start_line' => extract_line('$1')}).
SchemaDefinition -> 'schema' Directives '{' FieldDefinitionList '}' : build_ast_node('SchemaDefinition', #{'directives' => '$2', 'fields' => '$4'}, #{'start_line' => extract_line('$1')}).

ObjectTypeDefinition -> 'type' Name '{' FieldDefinitionList '}' :
  build_ast_node('ObjectTypeDefinition', #{'name' => extract_binary('$2'), 'fields' => '$4'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$5')}).
ObjectTypeDefinition -> 'type' Name Directives '{' FieldDefinitionList '}' :
  build_ast_node('ObjectTypeDefinition', #{'name' => extract_binary('$2'), 'directives' => '$3', 'fields' => '$5'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$6')}).
ObjectTypeDefinition -> 'type' Name ImplementsInterfaces '{' FieldDefinitionList '}' :
  build_ast_node('ObjectTypeDefinition', #{'name' => extract_binary('$2'), 'interfaces' => '$3', 'fields' => '$5'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$6')}).
ObjectTypeDefinition -> 'type' Name ImplementsInterfaces Directives '{' FieldDefinitionList '}' :
  build_ast_node('ObjectTypeDefinition', #{'name' => extract_binary('$2'), 'interfaces' => '$3', 'directives' => '$4', 'fields' => '$6'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$7')}).

ImplementsInterfaces -> 'implements' NamedTypeList : '$2'.

NamedTypeList -> NamedType : ['$1'].
NamedTypeList -> NamedType NamedTypeList : ['$1'|'$2'].

FieldDefinitionList -> FieldDefinition : ['$1'].
FieldDefinitionList -> FieldDefinition FieldDefinitionList : ['$1'|'$2'].
FieldDefinition -> Name ':' Type : build_ast_node('FieldDefinition', #{'name' => extract_binary('$1'), 'type' => '$3'}, #{'start_line' => extract_line('$1')}).
FieldDefinition -> Name ':' Type Directives : build_ast_node('FieldDefinition', #{'name' => extract_binary('$1'), 'type' => '$3', 'directives' => '$4'}, #{'start_line' => extract_line('$1')}).
FieldDefinition -> Name ArgumentsDefinition ':' Type : build_ast_node('FieldDefinition', #{'name' => extract_binary('$1'), 'arguments' => '$2', 'type' => '$4'}, #{'start_line' => extract_line('$1')}).
FieldDefinition -> Name Directives ':' Type : build_ast_node('FieldDefinition', #{'name' => extract_binary('$1'), 'directives' => '$2', 'type' => '$4'}, #{'start_line' => extract_line('$1')}).
FieldDefinition -> Name ArgumentsDefinition ':' Type Directives : build_ast_node('FieldDefinition', #{'name' => extract_binary('$1'), 'arguments' => '$2', 'directives' => '$5', 'type' => '$4'}, #{'start_line' => extract_line('$1')}).

ArgumentsDefinition -> '(' InputValueDefinitionList ')' : '$2'.

InputValueDefinitionList -> InputValueDefinition : ['$1'].
InputValueDefinitionList -> InputValueDefinition InputValueDefinitionList : ['$1'|'$2'].

InputValueDefinition -> Name ':' Type : build_ast_node('InputValueDefinition', #{'name' => extract_binary('$1'), 'type' => '$3'}, #{'start_line' => extract_line('$1')}).
InputValueDefinition -> Name ':' Type Directives : build_ast_node('InputValueDefinition', #{'name' => extract_binary('$1'), 'type' => '$3', 'directives' => '$4'}, #{'start_line' => extract_line('$1')}).
InputValueDefinition -> Name ':' Type DefaultValue : build_ast_node('InputValueDefinition', #{'name' => extract_binary('$1'), 'type' => '$3', 'default_value' => '$4'}, #{'start_line' => extract_line('$1')}).
InputValueDefinition -> Name ':' Type DefaultValue Directives : build_ast_node('InputValueDefinition', #{'name' => extract_binary('$1'), 'type' => '$3', 'default_value' => '$4', 'directives' => '$5'}, #{'start_line' => extract_line('$1')}).

InterfaceTypeDefinition -> 'interface' Name '{' FieldDefinitionList '}' :
  build_ast_node('InterfaceTypeDefinition', #{'name' => extract_binary('$2'), 'fields' => '$4'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$5')}).
InterfaceTypeDefinition -> 'interface' Name Directives '{' FieldDefinitionList '}' :
  build_ast_node('InterfaceTypeDefinition', #{'name' => extract_binary('$2'), 'directives' => '$3', 'fields' => '$5'}, #{'start_line' => extract_line('$1'), 'end_line' => extract_line('$6')}).

UnionTypeDefinition -> 'union' Name '=' UnionMembers :
  build_ast_node('UnionTypeDefinition', #{'name' => extract_binary('$2'), 'types' => '$4'}, #{'start_line' => extract_line('$1')}).
UnionTypeDefinition -> 'union' Name Directives '=' UnionMembers :
  build_ast_node('UnionTypeDefinition', #{'name' => extract_binary('$2'), 'directives' => '$3', 'types' => '$5'}, #{'start_line' => extract_line('$1')}).

UnionMembers -> NamedType : ['$1'].
UnionMembers -> NamedType '|' UnionMembers : ['$1'|'$3'].

ScalarTypeDefinition -> 'scalar' Name : build_ast_node('ScalarTypeDefinition', #{'name' => extract_binary('$2')}, #{'start_line' => extract_line('$2')}).
ScalarTypeDefinition -> 'scalar' Name Directives : build_ast_node('ScalarTypeDefinition', #{'name' => extract_binary('$2'), 'directives' => '$3'}, #{'start_line' => extract_line('$2')}).

EnumTypeDefinition -> 'enum' Name '{' EnumValueDefinitionList '}':
  build_ast_node('EnumTypeDefinition', #{'name' => extract_binary('$2'), 'values' => '$4'}, #{'start_line' => extract_line('$2'), 'end_line' => extract_line('$5')}).
EnumTypeDefinition -> 'enum' Name Directives '{' EnumValueDefinitionList '}':
  build_ast_node('EnumTypeDefinition', #{'name' => extract_binary('$2'), 'directives' => '$3', 'values' => '$5'}, #{'start_line' => extract_line('$2'), 'end_line' => extract_line('$6')}).

EnumValueDefinitionList -> EnumValueDefinition : ['$1'].
EnumValueDefinitionList -> EnumValueDefinition EnumValueDefinitionList : ['$1'|'$2'].

DirectiveDefinitionLocations -> Name : [extract_binary('$1')].
DirectiveDefinitionLocations -> Name '|' DirectiveDefinitionLocations : [extract_binary('$1')|'$3'].

EnumValueDefinition -> EnumValue : build_ast_node('EnumValueDefinition', #{'value' => extract_binary('$1')}, #{'start_line' => extract_line('$1')}).
EnumValueDefinition -> EnumValue Directives : build_ast_node('EnumValueDefinition', #{'value' => extract_binary('$1'), 'directives' => '$2'}, #{'start_line' => extract_line('$1')}).


InputObjectTypeDefinition -> 'input' Name '{' InputValueDefinitionList '}' :
  build_ast_node('InputObjectTypeDefinition', #{'name' => extract_binary('$2'), 'fields' => '$4'}, #{'start_line' => extract_line('$2'), 'end_line' => extract_line('$5')}).
InputObjectTypeDefinition -> 'input' Name Directives '{' InputValueDefinitionList '}' :
  build_ast_node('InputObjectTypeDefinition', #{'name' => extract_binary('$2'), 'directives' => '$3', 'fields' => '$5'}, #{'start_line' => extract_line('$2'), 'end_line' => extract_line('$6')}).


TypeExtensionDefinition -> 'extend' ObjectTypeDefinition :
  build_ast_node('TypeExtensionDefinition', #{'definition' => '$2'}, #{'start_line' => extract_line('$1')}).


Erlang code.

% Line-Level Utilities

extract_line({_Token, Line}) ->
  Line;
extract_line({_Token, Line, _Value}) ->
  Line;
extract_line(_) ->
  nil.

extract_child_line([Head|_]) ->
  extract_child_line(Head);
extract_child_line(#{loc := #{'start_line' := Line}}) ->
  Line;
extract_child_line(_) ->
  nil.


% Value-level Utilities

extract_atom({Value, _Line}) ->
  Value.

extract_binary(Value) when is_binary(Value) ->
  Value;

extract_binary({Token, _Line}) ->
  list_to_binary(atom_to_list(Token));

extract_binary({_Token, _Line, Value}) ->
  list_to_binary(Value).


% AST Generation

build_ast_node(Type, Node, #{'start_line' := nil}) ->
  build_ast_node(Type, Node, nil);
build_ast_node(Type, Node, Loc) ->
  'Elixir.Kernel':struct(list_to_atom("Elixir.Absinthe.Language." ++ atom_to_list(Type)), Node#{loc => Loc}).


% String

extract_quoted_string_token({_Token, _Line, Value}) ->
  iolist_to_binary(process_string(lists:sublist(Value, 2, length(Value) - 2))).

process_string(Escaped) ->
  process_string(Escaped, []).

process_string([], Acc) ->
  lists:reverse(Acc);
process_string([$\\, $" | T], Acc) ->
  process_string(T, [$" | Acc]);
process_string([$\\, $\\ | T], Acc) ->
  process_string(T, [$\\ | Acc]);
process_string([$\\, $/ | T], Acc) ->
  process_string(T, [$/ | Acc]);
process_string([$\\, $b | T], Acc) ->
  process_string(T, [$\b | Acc]);
process_string([$\\, $f | T], Acc) ->
  process_string(T, [$\f | Acc]);
process_string([$\\, $n | T], Acc) ->
  process_string(T, [$\n | Acc]);
process_string([$\\, $r | T], Acc) ->
  process_string(T, [$\r | Acc]);
process_string([$\\, $t | T], Acc) ->
  process_string(T, [$\t | Acc]);
process_string([$\\, $u, A, B, C, D | T], Acc) ->
  process_string(T, [hexlist_to_utf8_binary([A, B, C, D]) | Acc]);
process_string([H | T], Acc) ->
  process_string(T, [H | Acc]).

hexlist_to_utf8_binary(HexList) ->
  unicode:characters_to_binary([httpd_util:hexlist_to_integer(HexList)]).


% Block String

extract_quoted_block_string_token({_Token, _Line, Value}) ->
  iolist_to_binary(process_block_string(lists:sublist(Value, 4, length(Value) - 6))).

-spec process_block_string(string()) -> string().
process_block_string(Escaped) ->
  process_block_string(Escaped, []).

-spec process_block_string(string(), string()) -> string().
process_block_string([], Acc) ->
  block_string_value(lists:reverse(Acc));
process_block_string([$\r, $\n | T], Acc) -> process_block_string(T, [$\n | Acc]);
process_block_string([$\\, $", $", $" | T], Acc) -> process_block_string(T, [$", $", $"] ++ Acc);
process_block_string([H | T], Acc) -> process_block_string(T, [H | Acc]).

-spec block_string_value(string()) -> string().
block_string_value(Value) ->
  [FirstLine | Rest] = re:split(Value, "\n", [{return,list}]),
  Prefix = indentation_prefix(common_indent(Rest)),
  UnindentedLines = unindent(Rest, Prefix),
  Lines = trim_blank_lines([FirstLine | UnindentedLines]),
  string:join(Lines, "\n").

-spec trim_blank_lines([string()]) -> [string()].
trim_blank_lines(Lines) ->
  trim_blank_lines(trim_blank_lines(Lines, leading), trailing).

-spec trim_blank_lines([string()], leading | trailing) -> [string()].
trim_blank_lines(Lines, leading) ->
  lists:dropwhile(fun is_blank/1, Lines);
trim_blank_lines(Lines, trailing) ->
  lists:reverse(trim_blank_lines(lists:reverse(Lines), leading)).

-spec indentation_prefix(non_neg_integer()) -> string().
indentation_prefix(Indent) ->
  lists:map(fun(_) -> 32 end, lists:seq(1, Indent)).

-spec unindent([string()], string()) -> [string()].
unindent(Lines, Prefix) ->
  unindent(Lines, Prefix, []).

-spec unindent([string()], string(), [string()]) -> [string()].
unindent([], _Prefix, Result) ->
  lists:reverse(Result);
unindent([H | T], Prefix, Result) ->
  Processed = prefix(H, Prefix),
  unindent(T, Prefix, [Processed | Result]).

-spec prefix(string(), string()) -> string().
prefix(Line, []) ->
  Line;
prefix(Line, Prefix) ->
  Prefixed = lists:prefix(Prefix, Line),
  if
    Prefixed ->
      string:substr(Line, length(Prefix) + 1);
    true ->
      Line
  end.

-spec common_indent([string()]) -> non_neg_integer().
common_indent(Lines) ->
  case common_indent(Lines, noindent) of
    noindent ->
      0;
    Indent ->
      Indent
  end.

-spec common_indent([string()], noindent | non_neg_integer()) -> noindent | non_neg_integer().
common_indent([], Indent) ->
    Indent;
common_indent([H | T], Indent) ->
  CurrentIndent = leading_whitespace(H),
  if
    (CurrentIndent < length(H)) and ((Indent == noindent) or (CurrentIndent < Indent)) ->
      common_indent(T, CurrentIndent);
    true ->
      common_indent(T, Indent)
  end.

-spec leading_whitespace(string()) -> non_neg_integer().
leading_whitespace(BlockStringValue) ->
  leading_whitespace(BlockStringValue, 0).

-spec leading_whitespace(string(), non_neg_integer()) -> non_neg_integer().
leading_whitespace([], N) ->
  N;
leading_whitespace([32 | T], N) ->
  leading_whitespace(T, N + 1);
leading_whitespace([$\t | T], N) ->
  leading_whitespace(T, N + 1);
leading_whitespace([_H | _T], N) ->
  N.

-spec is_blank(string()) -> boolean().
is_blank(BlockStringValue) ->
    leading_whitespace(BlockStringValue) == length(BlockStringValue).


% Integer

extract_integer({_Token, _Line, Value}) ->
  {Int, []} = string:to_integer(Value), Int.


% Float

extract_float({_Token, _Line, Value}) ->
  {Float, []} = string:to_float(Value), Float.


% Boolean

extract_boolean({_Token, _Line, "true"}) ->
  true;
extract_boolean({_Token, _Line, "false"}) ->
  false.
