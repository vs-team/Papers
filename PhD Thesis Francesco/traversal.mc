Module "RecordUpdater" => (r : Record) : RecordUpdater {
  Func "update" -> r.RecordType -> float : r.RecordType
}

Module "FieldUpdater" => (r : Record) => (name : string) : FieldUpdater {
  Func "update" -> r.RecordType -> float : (GetFieldType r name)
}

Module "ElementUpdater" => (elementType : *) : ElementUpdater {
  Func "update" -> elementType -> float : elementType
}

Functor "NoUpdate" : RecordUpdater
Functor "Update" => FieldUpdater => RecordUpdater => float : RecordUpdater
Functor "EntityUpdater" => RecordUpdater => string => float : FieldUpdater
Functor "TupleUpdater" => FieldUpdater => TupleUpdater => string => float : FieldUpdater
Functor "ListUpdater" => RecordUpdater => string => float : FieldUpdater
Functor "GetFieldType" => Record => string : *

GetField r name => getter
getter.GetType => type
---------------------------
GetFieldType r name => type


---------------------
ZeroUpdate r name => FieldUpdater r name {

  GetField r name => getter
  getter.get r -> v
  ----------------
  update r dt -> v
}

---------------------
NoUpdate => RecordUpdater EmptyRecord {
  
  ----------------
  update r dt -> r
}


---------------------------
Update (FieldUpdater r name) nextUpdate => RecordUpdater r {

  fu := FieldUpdater r name
  SetField r name => setter
  fu.update r dt -> v
  setter.set r v -> r'
  nextUpdate.update r' dt -> updatedRecord
  ----------------------------
  update r dt -> updatedRecord
}

----------------------------------------
EntityUpdater (RecordUpdater r) name dt => FieldUpdater r name {

  eUpdater := RecordUpdater r
  GetField r name => getter
  getter.get r -> entity
  eUpdater.update entity dt -> entity'
  -----------------------------
  update r dt -> entity'
}


----------------------------------
ListUpdater (RecordUpdater r) name dt => FieldUpdater r name {

  Func "updateList" -> List[r.RecordType] : List[r.RecordType]

  -------------------
  updateList nil -> nil

  ru := RecordUpdater r
  ru.update x dt -> x'
  updateList xs -> xs'
  ---------------------
  updateList (x :: xs) -> (x' :: xs')

  ru := RecordUpdater r
  GetField r name => getter
  getter.get r => l
  updateList l -> l'
  ---------------------
  update r dt -> l'
}