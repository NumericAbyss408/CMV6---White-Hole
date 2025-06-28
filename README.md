# CMV6 - White-Hole
An Object-Oriented Programming module Designed to work in Lua and more specifically the Roblox Studio engine

Hello People!
as we developers go from the beginners to the advanced level of programming, the techniques and paradigms we use must follow. <br/>
Lua allows you to create object oriented structures using table, but they only really see good use in modulescripts, and are hence a little hard to contain.  
I decided to create my own version, which allows for better definition of multiple classes across all kinds of scripts and puts emphasis on typechecking for a smooth experience, as well as a complete trifecta of Encapsulation, Inheritance and Polymorhphysm.

## When could you use it
It works especially well for large structures that usually benefit from object-oriented design - whether that be the classic data structures (Linked lists, Queues, Stacks, Trees), all the way to more intricate components, such as whole weapons, or even large systems (like a procedural track generator.)

## How it works
Admittedly, in an effort to keep the module self-contained, the syntax is a *little* verbose.

first, of course, you need the module. there are 2 ways of doing so: <br/>
**Method 1**
```
_ = require(path.to.ClassModuleV6)
CLS = _.factory({})
```
**Method 2**
```
CLS = require(path.to.ClassModuleV6).factory({})
```
both are functionally equivalent. when requiring a module, a function is returned which expects an empty table.
this table will store all the classes you create, as well as helper classes that come with the module.
The difference between the two is that method 1, storing the module as "_", allows for the module to be typechecked properly during module definition,
which will be explained below.  

Defining a class:  
Classes are defined as follows:
```
CLS.[ClassNameHere] = CLS().Define(
	CLS().Shell(),
	CLS().Nucleus(function(Class)
		local self,self_ = Class.Self({},{})

		----------------------------------------------------------------------------------
		--Body Here -  should mainly be function, members should be defined within INIT --
		----------------------------------------------------------------------------------

		return Class.Pack(self,self_)
	end),
	CLS().Neutrons()
)
```
**The breakdown**:<br/>
`CLS().Shell()` constitutes the data and metadata associated with a class.
`Shell()` expects at least a **class name**. you may choose to add the following to it (in the order specified):  
- a description string #  
- a boolean describing whether it is a singleton  
- a list of strings containing the class names of depenency class #
- a table with two keys: #
 -	Finished: a boolean determining whether implementation is finished
 -	Notes: a string containing further notes on the class, such as what needs to be implemented.

*Note: Any of the above listed with a # are only metadata and not used by the system in any way. you can omit them with `nil`.  
omitting the singleton boolean with `nil` means the class will assume it is NOT a singleton.*

`CLS().Nucleus()` contains the actual body of the class.  
It expects a function that takes a table of type "Class" and returns a table populated with two tables.  
On Roblox, if you used **Method 1** to set up your module, you can expect the typechecker to provide an anonymous function autocomplete that looks like so:
```
(function(Class:_.Class)

end)
```

This function holds your class body.
two lines are required for this body to sustain itself:
`local self,self_ = Class.Self({},{})` at the very start of the body 
and  
`return Class.Pack(self,self_)` at the very end of the body.

`Class.Self()` takes two empty tables, and converts them into unsealed public and private tables.  
`self` will usually start empty, and `self_` will show two keys:
- INIT: a table which you override with a function that can take any arguments you define for it and that returns `self` (Required for the class to work, errors otherwise),
- SUPER: a function that calls the init of the superclass the current class inherits from. it cannot be called if a superclass is not specified.
  
You can pass an additional `CLS.[ParentClassName].asSuper`, to have this class you are defining inherit from this passed class. Doing so also allows self_ to access the `SUPER()` method in `self_`.

`CLS().Neutrons()` expects a table containing class-wide methods and attributes. these can then be accessed by referencing the through the class.

the result of this definition is a class.
```
CLS.Example = CLS().Define(...
)
```
after definition, you have the following options:
```
CLS.Example.New()
           .asSuper()
           .HasInstance() -- determines whether the passed object is of this class. subclass instances will return true as well.
           .InstanceCount -- the number of instances that were created
```

  
Nifty.  

## Considerations
while the need for changes is diminishing, this is still in active development. *can't really consider it closed until each instance has a `destroy()` function*.  
The module is pretty strict - it will error when:
- you attempt to modify the class outside of the definition body
- you attempt to instance a singleton more than once
- you omit the class name *(duh)*
- you attempt to change something via a `SUPER()` call (like: `SUPER().someCriticalFunc = overriderFunc`).

## Example Usage:
![codeimage-snippet_28](https://github.com/user-attachments/assets/719939a3-8418-4107-bac3-e1658f70a778)(this comes pre-packaged as part of a set of helper classes. they are readily available as soon as the factory is created.)
