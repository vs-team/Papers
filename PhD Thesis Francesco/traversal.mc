Module "RecordUpdater" => (r : Record) : RecordUpdater {
  Functor "RecordType" : *
  Func "update" -> r.RecordType -> float : r.RecordType
}

Module "FieldUpdater" => (r : Record) => (name : string) : FieldUpdater {
  Functor "GetRecord" : Record
  Func "update" -> r.RecordType -> float : (GetFieldType r name)
}

Module "ElementUpdater" => (elementType : *) : ElementUpdater {
  Functor "GetType" : *
  Func "update" -> elementType -> float : elementType
}

Functor "NoUpdate" => Record : RecordUpdater
Functor "Update" => FieldUpdater => RecordUpdater : RecordUpdater
Functor "UpdateField" => ElementUpdater => Record => string : FieldUpdater
Functor "UpdateEntity" => RecordUpdater : ElementUpdater
Functor "UpdateTuple" => ElementUpdater => ElementUpdater : ElementUpdater
Functor "UpdateList" => ElementUpdater : ElementUpdater
Functor "ZeroUpdate" => * : ElementUpdater
Functor "GetFieldType" => Record => string : *
Functor "Rule" => Record => string : FieldUpdater

GetField r name => getter
getter.GetType => type
---------------------------
GetFieldType r name => type


-----------------------
ZeroUpdate type => ElementUpdater type {

  ----------------
  GetType => type

  ----------------
  update v dt -> v
}

recordUpdater.RecordType => recordType
--------------------------
UpdateEntity recordUpdater => ElementUpdater recordType {

  -----------------------
  GetType => recordType

  
  recordUpdater.update entity dt -> entity'
  ------------------------------
  update entity dt -> entity'
}

updater.GetType => elementType
---------------------------------
UpdateList updater => ElementUpdater List[elementType] {

  -----------------
  GetType => List[elementType]

  --------------------
  update nil dt -> nil

  updater.update x dt -> x'
  update xs dt -> xs'
  -------------------
  update (x :: xs) dt -> (x' :: xs')
}

updater.GetType => firstType
nextUpdater.GetType => nextType
---------------------------------------------
UpdateTuple updater nextUpdater => ElementUpdater Tuple[firstType,nextType] {

  -------------------
  GetType => Tuple[firstType,nextType]

  updater.update x dt -> x'
  nextUpdater.update x' dt -> xs'
  ----------------------
  update (x,xs) dt -> (x',xs')
}

---------------------
NoUpdate r => RecordUpdater r {

  r.RecordType => recordType
  ----------------------
  RecordType => recordType
  
  ----------------
  update r dt -> r
}

fieldUpdater.GetRecord => r
---------------------------
Update fieldUpdater nextUpdater => RecordUpdater r {

  r.RecordType => recordType
  ------------------------
  RecordType => recordType

  SetField r name => setter
  fieldUpdater.update rec dt -> v
  setter.set rec v -> rec'
  nextUpdater.update rec' dt -> updatedRecord
  ----------------------------
  update rec dt -> updatedRecord
}

----------------------------------------
UpdateField elementUpdater r name => FieldUpdater r name {

  ---------------
  GetRecord => r

  GetField r name => getter
  getter.get rec -> field
  elementUpdater.update field dt -> field' 
  -----------------------------
  update rec dt -> field'
}

//PHYSICAL BODY

Functor "PhysicalBodyType" : Record
Functor "BodyUpdater" : RecordUpdater
Functor "FloatUpdater" : ElementUpdater
Functor "PositionRule" : FieldUpdater
Functor "VelocityRule" : FieldUpdater
Func "physicalBody" : PhysicalBodyType

RecordField "Acceleration" Tuple[float,float] EmptyRecord => acceleration
RecordField "Velocity" Tuple[float,float] acceleration => velocity
RecordField "Position" Tuple[float,float] velocity => body
---------------------------
PhysicalBodyType => body

ZeroUpdate float => update
---------------------
FloatUpdater => update


--------------------------------
PositionRule => FieldUpdater PhysicalBodyType "Position" {

  ---------------------
  GetRecord => PhysicalBodyType

  getPos body -> position
  getVel body -> velocity
  << position + velocity * dt >> -> position'
  ---------------------------
  update body dt -> position'
}

--------------------------------
VelocityRule => FieldUpdater PhysicalBodyType "Velocity" {

  --------------------
  GetRecord => PhysicalBodyType

  getVel body -> velocity
  getAcc body -> acceleration
  << velocity + acceleration * dt >> -> velocity'
  ---------------------------
  update body dt -> velocity'
}

UpdateTuple FloatUpdater FloatUpdater => vectorUpdater
UpdateField vectorUpdater PhysicalBodyType "Position" => posUpdate  
UpdateField vectorUpdater PhysicalBodyType "Velocity" => velUpdate  
UpdateField vectorUpdater PhysicalBodyType "Acceleration" => accUpdate
NoUpdate PhysicalBodyType => zero
Update VelocityRule zero => velRule
Update PositionRule velRule => posRule
Update accUpdate posRule => accFieldUpdate
Update velUpdate accFieldUpdate => velFieldUpdate
Update posUpdate velFieldUpdate => bodyUpdater
--------------------------
BodyUpdater => bodyUpdater





BodyUpdater.update body dt -> body'
---------------------------
updateBody body dt -> body'

--------------------------------------------------------------------
updateBody ((1.0,1.0),((0,0,0.0),((3.0,3.0),()))) 1.0 -> updatedBody

//WORLD
Functor "WorldType" : Record
Functor "WorldUpdater" : RecordUpdater
Functor "BodiesUpdater" : FieldUpdater

RecordField "PhysicalBodies" List[PhysicalBodyType] EmptyRecord => world
---------------------------------
WorldType => world

UpdateEntity BodyUpdater => bodyUpdater
UpdateList bodyUpdater => listUpdater
UpdateField listUpdater WorldType "PhysicalBodies" => fieldUpdater
NoUpdate WorldType => zero
Update fieldUpdater zero => worldUpdater
--------------------------------------
WorldUpdater => worldUpdater

//COROUTINES

//example
entity PhysicalBody = {
  Position        : Tuple[float,float]
  Velocity        : Tuple[float,float]
  Acceleration    : Tuple[float,float]

  rule Position = Position + Velocity * dt
  rule Velocity = Velocity + Acceleration * dt
  rule Velocity =
    wait Position.X < 0 || Position.X > 640 || Position.Y < 0 || Position.Y > 480
    yield (-Velocity.X,-Velocity.Y)
}

Module "FieldUpdater" => (r : Record) => (name : string) : FieldUpdater {
  Functor "GetRecord" : Record
  Func "update" -> r.RecordType -> float : Tuple[(GetFieldType r name),stmt]
}

Functor "Coroutine" => Record => string => stmt : FieldUpdater

-----------------------
Coroutine r name stmts => FieldUpdater r name {

  Func "tick" -> r.RecordType -> List[stmt] -> float : Tuple[r.RecordType,stmt]
  Func "eval_s" -> r.RecordType -> stmt -> float : Tuple[r.RecordType,stmt]

  -----------------------------
  GetRecord => PhysicalBodyType


  eval_s body stmts dt -> (res,updatedStatements)
  --------------------------
  tick body nop dt -> (res,updatedStatements)


  eval_s body stmt dt -> (res,updatedStatements)
  -----------------------------
  tick body stmt dt -> (res,updatedStatements)


  -------------------------
  eval_s nop nop dt -> (v,nop)

  addStmt b k -> cont
  eval_s a cont ctxt dt -> (v,k)
  -------------------------------
  eval_s (a;b) k ctxt dt -> (v,k)

  GetField r name => getter
  getter.get body -> (v,k)
  tick body k dt -> (v',k')
  -------------------------
  update body dt -> (v',k')
}