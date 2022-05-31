# The query language 
This is the specifications of the query language. This spec will change in the future.
```
> QUERY: FIND_FUNCTION ^ DATASTORE_FILTER

FIND_FUNCTION: { $find: MATCH_BODY }
DATASTORE_FILTER: { "_datastore": DATASTORE_NAME }
DATASTORE_NAME: ^[a-zA-Z_][a-zA-Z_0-9-]*$

MATCH_BODY: { MATCH_PROPERTY* }
MATCH_PROPERTY: BOOLEAN_MATCHING_FUNCTION | PROPERTY_CHECK
PROPERTY_CHECK: {PROPERTY_CHECK_KEY: PROPERTY_CHECK_VALUE}
PROPERTY_CHECK_VALUE: MATCH_BODY | NOT_OBJECT_VALUE
PROPERTY_CHECK_KEY: ^[a-zA-Z_][a-zA-Z_0-9-]*$

NOT_OBJECT_VALUE: STRING | NUMBER | BOOLEAN | ARRAY[T]
VALUE: NOT_OBJECT_VALUE | OBJECT
ARRAY[T]: # Array of "type" T ex: [1, 2, 3] 
STRING: # any quoted string ex: "Hello World"
NUMBER: # Any positive, negative or floating number.
BOOLEAN: true | false
OBJECT: # Any json object ex: {a: {b: "hello", d: 42 }}

BOOLEAN_MATCHING_FUNCTION:
    MATCH_MATCHING_FUNCTION | 
    EQ_MATCHING_FUNCTION | 
    AND_MATCHING_FUNCTION | 
    OR_MATCHING_FUNCTION | 
    LT_MATCHING_FUNCTION | 
    GT_MATCHING_FUNCTION | 
    NOT_MATCHING_FUNCTION

EQ_MATCHING_FUNCTION: { $eq: VALUE } 
MATCH_MATCHING_FUNCTION:  { $match: MATCH_BODY }
AND_MATCHING_FUNCTION: { $and: ARRAY[MATCH_BODY] }
OR_MATCHING_FUNCTION: { $or:  ARRAY[MATCH_BODY] }
NOT_MATCHING_FUNCTION: { $not: MATCH_BODY }
GT_MATCHING_FUNCTION: { $gt: NUMBER }
LT_MATCHING_FUNCTION: { $lt: NUMBER }


# For future usage.
# BOOLEAN_FUNCTION: MATCH_FUNCTION | EQ_FUNCTION | AND_FUNCTION | OR_FUNCTION | LT_FUNCTION | GT_FUNCTION | NOT_FUNCTION 
# BOOLEAN_FUNCTION_LIST: BOOLEAN_FUNCTION+ 


# EQ_FUNCTION: { $eq: [ VALUE, VALUE ] }
# MATCH_FUNCTION:  { $match: [ VALUE, MATCH_BODY ] }
# AND_FUNCTION: { $and:  [ VALUE, BOOLEAN_MATCHING_FUNCTION_LIST ] | BOOLEAN_FUNCTION_LIST }
# OR_FUNCTION: { $or:  [ VALUE, BOOLEAN_MATCHING_FUNCTION_LIST ] | BOOLEAN_FUNCTION_LIST }
# NOT_FUNCTION: { $not: [ VALUE, MATCH_BODY ] | BOOLEAN_FUNCTION }
# GT_FUNCTION: { $gt: [ NUMBER, NUMBER ] }
# LT_FUNCTION: { $lt: [ NUMBER, NUMBER ] }
```

How to read this ?
- Start with the '>' (Query)
- Follow the possible branch
  - | : XOR - take exactly one
  - ^ : AND - take all elements (and merge the object properties if needed)
  - ? : optional. You dont have to take it.
  - + : At least One of the previous element (and merge the object properties if needed)
  - "...": Specific string value
  - $...^: String matching the regex

## Examples
### Take All data from a specific _datastore
```JSON
{
    "_datastore": "MyDatastore",
    "$find": {}
}
```

### Take All data from a specific _datastore with a specific _id
```JSON
{
    "_datastore": "MyDatastore",
    "$find": {
        "_id": 42
    }
}
```