---!strict
local CMV6 = {}
RS = game:GetService("RunService")

type BodyReturn<A,B> = {self:A,self_:B}

export type Body<A,B> = (Class:ClassHelper)->BodyReturn<A,B>

CM_ = {}
CM_.AuxiliaryFunctions = function(Metadata:Shell)
	return {
		self = function<A,B,U,R>(self:A,self_:B,Parent:BodyReturn<U,R>)
			if not Parent then
				Parent = {
					self = {},
					self_ = setmetatable({},{__ClassNames = {}})
				} :: BodyReturn<U,R>
			end
			
			--PHASE 1/2 - BRONZE SUPER
			local SUPERTABLE = {}
			SUPERTABLE.OSELF = setmetatable({},{__index = Parent.self})
			SUPERTABLE.self = setmetatable(
				{},
				{
					__index = SUPERTABLE.OSELF::U,
					__newindex = function() error("ATTEMPT TO OVERWRITE VIA SUPER") end
				}
			)
			SUPERTABLE.OSELF_ = setmetatable({},{__index = Parent.self_})
			SUPERTABLE.self_ = setmetatable(
				{},
				{
					__index = SUPERTABLE.OSELF_::R,
					__newindex = function() error("ATTEMPT TO OVERWRITE VIA SUPER") end
				}
			)
			--Parent.self_.INIT = nil
			
			--PHASE 1 - GOLD SELF
			self = setmetatable(
				self,
				{
					__index = Parent.self :: U,
					__call = function() return SUPERTABLE.self :: U end,
					__newindex = function(t,k,v)
						if typeof(Parent.self[k]) == "function" then
							SUPERTABLE.OSELF[k] = Parent.self[k]
						end
						Parent.self[k] = v
					end,
				}
			)
			--PHASE 2 - SILVER SELF_
			--Parent.self_.SUPER = Parent.self_.INIT
			
			
			self_ = setmetatable(
				self_,
				{
					__index = Parent.self_ :: setmetatable<{INIT:{"Function returning self"}},{__index:R}>,
					__call = function() return SUPERTABLE.self_ :: R end,
					__newindex = function(t,k,v)
						if typeof(Parent.self_[k]) == "function" then
							SUPERTABLE.OSELF_[k] = Parent.self_[k]
						end
						Parent.self_[k] = v
					end,
					__ClassNames =(function()
						local ParentNames = getmetatable(Parent.self_).__ClassNames :: {string}
						ParentNames[#ParentNames+1] = Metadata.Name
						return ParentNames
					end)()
				}
			)
			return self,self_
		end,
		Attribute = function() end,
		Pack = function(self,self_)
			return {
				self = self,
				self_ = self_
			}
		end
	}
end
export type ClassHelper = typeof(CM_.AuxiliaryFunctions())

FactoryFunctions = (function()
	local FactoryFunctions = {}
	FactoryFunctions.Shell = function(
		name:string,
		description:string,
		IsSingleton:boolean,
		classDependencies:{string},
		State:{Finished:boolean,Notes:string}
	)---------------------------------------------------------------------
		return {
			Name = name,
			Description = description or "",
			IsSingleton = IsSingleton or false,
			Dependencies = classDependencies or {},
			Details = State or {Finished = false, Notes = "N/A"}
		}
	end
	export type Shell = typeof(FactoryFunctions.Shell())
	FactoryFunctions.Nucleus = function<A,B>(b:Body<A,B>)
		return b
	end
	
	FactoryFunctions.Neutrons = function<TBL>(T:TBL)
		return T
	end
	
	FactoryFunctions.Define = function<X,Y,Neuts>(
		Element:Shell,
		Nucleus:Body<X,Y>,
		Neutrons:Neuts
	)
		if not Element.Name then error("Missing Class Name") end
		
		local ClassFactory = {}
		ClassFactory.InstanceCount = 0
		
		local MetaIDX = function<A,B>(Target:BodyReturn<A,B>)
			local MetaTBL = {}
			MetaTBL.__index = Target.self
			MetaTBL.__newindex = function(t,k,v)
				if typeof(Target.self[k]) == "function" then
					error("ATTEMPT TO MODIFY FUNCTION: "..k)
				elseif Target.self[k] ~= nil then Target.self[k] = v
				else
					warn(k, "was added as an object attribute.")
					rawset(t,k,v)
				end
			end
			MetaTBL.__private = Target.self_
			MetaTBL.__ID = Element.Name.." @"..ClassFactory.InstanceCount
			MetaTBL.__tostring = function() return MetaTBL.__ID end
			return MetaTBL
		end
		
		ClassFactory.HasInstance = function<I,J>(Object:BodyReturn<I,J>)
			local ClassNames = getmetatable(Object.self_).__ClassNames
			if table.find(ClassNames,Element.Name) then return true
			else return false
			end
		end
		
		ClassFactory.AsSuper = function() : BodyReturn<X,Y>
			return Nucleus(CM_.AuxiliaryFunctions(Element))
		end
		
		ClassFactory.New = function(...)
			if Element.IsSingleton and ClassFactory.InstanceCount >= 1 then
				error("Class defined as singleton attempted to be instanced more than once")
			end
			if not Element.Details.Finished and not RS:IsStudio() then
				warn("Unfinished class is running outside of studio")
			end
			ClassFactory.InstanceCount += 1
			local NeoInstance = Nucleus(CM_.AuxiliaryFunctions(Element))
			NeoInstance.self_.INIT(...)
			--print(getmetatable(NeoInstance.self_).__ClassNames)
			return setmetatable({},MetaIDX(NeoInstance))
			
		end :: index<Y,"INIT">
		setmetatable(ClassFactory,{__index = Neutrons}) --:: setmetatable<typeof(ClassFactory),{__index:Neutrons}>
		return ClassFactory
	end
	return FactoryFunctions
end)()
local Factory = function<A>(t:A)
	
	return setmetatable(
		t,
		{
			__call = function(t)
				return FactoryFunctions
			end,
		}
	)
	
end

local ExampleFactory = Factory({})
ExampleFactory.Test = ExampleFactory().Define(
	ExampleFactory().Shell(
		"Test",
		"",
		true,
		{},
		{Finished=false,Notes=""}
	),
	ExampleFactory().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{})
	
		self.one = 1
		self_.INIT = function(unos)
			return self
		end
		self.Reiter = function()
			return ExampleFactory.Test.New()
		end
		
		return Class.Pack(self,self_)
	end),
	ExampleFactory().Neutrons({
		CertainConstant = 0
	})
)

ExampleFactory.Test2 = ExampleFactory().Define(
	ExampleFactory().Shell("Test2"),
	ExampleFactory().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{},ExampleFactory.Test.AsSuper())
		
		self_.INIT = function() return self end
		
		return Class.Pack(self,self_)
	end),
	ExampleFactory().Neutrons({})
)

local Helpers = Factory({})

Helpers.Stack = Helpers().Define(
	Helpers().Shell(
		"Stack",
		"A Stack ABDAST",
		false,
		{},
		{Finished = true, Notes = "Ready for anything."}
	),
	Helpers().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{})
		self_.INIT = function<A>(StackType:A)
			StackType = nil --purely for typecheck purposes
			self_.Top = 0
			self_.Stack = {}

			self.IsEmpty = function() return (self_.Top <=0) end

			self.Push = function(Data:A) -- pushes the passed data argument to the top of the stack
				self_.Stack[self_.Top+1] = Data
				self_.Top += 1
			end

			self.Length = function() -- returns the height of the stack
				return self_.Top
			end

			self.Peek = function() : A -- returns the latest value in the stack
				return self_.Stack[self_.Top]
			end

			self.Pop = function() : A -- returns the latest value in the stack and "removes" from the stack
				if not self.IsEmpty() then
					local rValue = self.Peek()
					self_.Top -= 1
					return rValue
				end
			end

			self.Range = function(n:number) -- returns the top n items of the stack, as an iterable
				self_.Traveller = self_.Top
				local Iterable = {}
				for count = 1,n do
					Iterable[count] = self_.Stack[self_.Top-(count-1)]
				end
				return Iterable
			end

			self.Reverse = function()
				local NewStack = Helpers.Stack.New()
				local Iterables = self.Range(self.Length())
				for _,item in Iterables do
					task.wait()
					NewStack.Push(item)
				end
				--print(NewStack.Length())
				return NewStack
			end
			return self
		end
		
		return Class.Pack(self,self_)
	end),
	Helpers().Neutrons({})
)
export type Stack = typeof(Helpers.Stack.New())

Helpers.Tree = Helpers().Define(
	Helpers().Shell(
		"Tree","a tree ABDAST",
		false,
		{},
		{Finished = false,Notes = "started, still deciding how indexing should work."}
	),
	Helpers().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{})
		
		self_.INIT = function() return self end
		
		self_.Root = nil::TreeNode
		
		self.SetRoot = function(Node:TreeNode)
			self_.Root = Node
		end
		
		self.GetRoot = function()
			return self_.Root
		end
		
		self.PreOrderTraverse = function(Node:TreeNode) : {TreeNode}
			local rT = {}
			
			local function TraverseFunction(node:TreeNode)
				rT[#rT+1] = node
				for _,child in node.GetChildren() do
					TraverseFunction(child)
				end
			end
			
			TraverseFunction(Node)
			
			return rT
		end
		
		self.PostOrderTraverse = function(Node:TreeNode) : {TreeNode}
			local rT = {}

			local function TraverseFunction(node:TreeNode)
				for _,child in node.GetChildren() do
					TraverseFunction(child)
				end
				rT[#rT+1] = node
			end
			
			TraverseFunction(Node)
			
			return rT
		end
		
		return Class.Pack(self,self_)
	end),
	Helpers().Neutrons({
		Node = Helpers().Define(
			Helpers().Shell("TreeNode","",false,{},{Finished = true, Notes = "doubt there's anything left to do."}),
			Helpers().Nucleus(function(Class: ClassHelper) 
				local self,self_ = Class.self({},{})
				self_.INIT = function(Data:any)
					
					self.Data = Data
					
					self_.Children = {} :: {typeof(self)}
					
					return self
				end
				
				self.AddNode = function(Node:TreeNode)
					self_.Children[#self_.Children+1] = Node
					return Node
				end
				
				self.GetChildren = function() :{TreeNode}
					return self_.Children
				end
				self.RemoveNode = function(Node:TreeNode)
					table.remove(self_.Children,table.find(self_.Children,Node))
				end
				
				return Class.Pack(self,self_)
			end),
			Helpers().Neutrons({})
		)
	})
)
export type Tree = typeof(Helpers.Tree.New())
export type TreeNode = typeof(Helpers.Tree.Node.New())

Helpers.BTree = Helpers().Define(
	Helpers().Shell(
		"BTree","a binary tree ABDAST",
		false,
		{},
		{Finished = false,Notes = "started, still deciding how indexing should work."}
	),
	Helpers().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{},Helpers.Tree.AsSuper())

		self_.INIT = function() return self end

		self.InOrderTraverse = function(Node:BTreeNode) : {BTreeNode}
			local rT = {}

			local function TraverseFunction(node:BTreeNode)
				if node.GetChildren()[1] then TraverseFunction(node.GetChildren()[1]) end
				rT[#rT+1] = node
				if node.GetChildren()[2] then TraverseFunction(node.GetChildren()[2]) end
			end

			TraverseFunction(Node)
			
			return rT
		end

		return Class.Pack(self,self_)
	end),
	Helpers().Neutrons({
		BTNode = Helpers().Define(
			Helpers().Shell("BTreeNode","",false,{},{Finished = true, Notes = "doubt there's anything left to do."}),
			Helpers().Nucleus(function(Class: ClassHelper) 
				local self,self_ = Class.self({},{},Helpers.Tree.Node.AsSuper())

				self.AddNode = function(Node:TreeNode)
					if #self_.Children < 2 then
						self_.Children[#self_.Children+1] = Node
					end
					return Node
				end

				return Class.Pack(self,self_)
			end),
			Helpers().Neutrons({})
		)
	})
)
export type BTree = typeof(Helpers.BTree.New())
export type BTreeNode = typeof(Helpers.BTree.BTNode.New())

Helpers.Util = {}
Helpers.Util.Timer = Helpers().Define(
	Helpers().Shell(
		"Timer","A timer to time your code",
		false,
		{},
		{Finished = false, Notes = "Should be relatively easy to build."}
	),
	Helpers().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{})
		self_.INIT = function() return self end
		
		self_.TaskName = ""
		
		self_.StartTime = 0
		
		self_.Started = false
		
		self.Start = function(TaskName:string)
			if not self_.Started then
				self_.Started = true
				self_.TaskName = TaskName
				self_.StartTime = tick()
				warn(`Started task {self_.TaskName}.`)
			else
				warn("Timer is already active.")
			end
		end
		
		self.Stop = function()
			if self_.Started then
				self_.Started = false
				local ETime = tick()-self_.StartTime
				warn(`Task {self_.TaskName} ran for {ETime}s.`)
			else
				warn("No tasks currently running.")
			end
		end
		
		
		
		return Class.Pack(self,self_)
	end),
	Helpers().Neutrons({})
)

Helpers.Discrete = {}
Helpers.Discrete.ProbabilityTree = Helpers().Define(
	Helpers().Shell(
		"ProTree","a Probability Tree ABDAST",
		false,
		{},
		{Finished = false,Notes = "started, still deciding how indexing should work."}
	),
	Helpers().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{},Helpers.Tree.AsSuper())
		
		self_.Root = self_.Root :: Event
		
		self_.INIT = function() 
			self.SetRoot(Helpers.Discrete.ProbabilityTree.Event.New("Start",1))
			return self 
		end
		
		self_.Target = nil :: Event
		
		self_.Choices = {}
		self_.SetChoices = function(start:Event)
			self_.IsWhole = true
			self_.Choices = {}
			
			local function Normalize(Node:Event)
				local TotalWeight = 0
				for i,child:Event in Node.GetChildren() do
					task.wait()
					child = child :: Event
					TotalWeight += child.Data.GivenWeight
				end
				for i,child:Event in Node.GetChildren() do
					task.wait()
					child = child :: Event
					child.Data.TrueWeight = child.Data.GivenWeight/TotalWeight
				end
			end
			
			local function Traverse(Node:Event,Multiplier:number)
				Multiplier = Multiplier or 1
				Normalize(Node)
				for i,child:Event in Node.GetChildren() do
					--task.wait()
					child = child :: Event
					if child.Data.GivenWeight > 0 then
						if #child.GetChildren() == 0 then
							self_.Choices[#self_.Choices+1] = {child.Data.TrueWeight * Multiplier,child.Data.Name}
						else
							Traverse(child,child.Data.TrueWeight * Multiplier)
						end
					end
				end
			end
			
			
			
			Traverse(start)
			table.sort(self_.Choices,function(a0, a1): boolean 
				if a0[1] < a1[1] then return true
				else return false end
			end)
			self_.UltraNormalze()
		end
		
		self_.UltraNormalze = function()
			local t = 0
			for i,pair in self_.Choices do
				t+= pair[1]
			end
			for i,pair in self_.Choices do
				pair[1] /= t
			end
		end
		
		self_.IsWhole = false
		
		self_.RChoose = function(Given:Event|"Start", Mode:"Replace"|"NoReplace"|boolean) : (string,number)
			Mode = Mode or "NoReplace"
			assert(Mode == "Replace" or Mode == "NoReplace" or type(Mode) == "boolean", "Incorrect choose mode")
			if 
				not self_.Target or #self_.Choices == 0 
			then
				if Given == "Start" or Given == nil then 
					self_.Target = self_.Root
				else 
					self_.Target = Given
				end
				self_.SetChoices(self_.Target)
			end
			local Rnd = math.random()
			self_.UltraNormalze()
			if Mode == true or Mode == "Replace" then
				for i,choice in self_.Choices do
					if choice[1] > Rnd then return choice[2], i end
				end
				return self_.Choices[#self_.Choices][2], #self_.Choices
			elseif Mode == false or Mode == "NoReplace" then
				self_.IsWhole = false
				for i,choice in self_.Choices do
					if choice[1] > Rnd then 
						return table.remove(self_.Choices,i)[2], i
					end
				end
				return table.remove(self_.Choices,#self_.Choices)[2], #self_.Choices
			end
		end
		
		self.isWhole = function() return self_.IsWhole end
		
		self.Replenish = function(Target)
			if Target then self_.Target = Target end
			if not self_.Target then 
				self_.Target = self_.Root
			end
			self_.SetChoices(self_.Target)
		end
		
		self.GetNRemainingLeaves = function() return #self_.Choices end
		
		self.RChoose = function(Given:Event|"Start", Mode:"Replace"|"NoReplace"|boolean) :string
			local result = self_.RChoose(Given,Mode)
			return result
		end
		
		--[[Similar to self.RChoose:chooses between leaf nodes randomly. allows for a condition to be attatched, striking the leaf from future choices if the function returns true.]]
		self.Choose_CR = function(Given:Event|"Start",Condition:(Cresult:string)->boolean, onExhaustion:()->()) :string
			local Result,Index = self_.RChoose(Given,"Replace")
			local Check = Condition(Result)
			if Check == true then
				self_.IsWhole = false
				table.remove(self_.Choices,Index)
				if #self_.Choices == 0 and onExhaustion ~= nil then
					onExhaustion()
				end
			elseif Check == false then
				task.wait()
			elseif typeof(Check) ~= "boolean" then error("Function returned an incorrect type (must be boolean)") end
		end
		
		return Class.Pack(self,self_)
	end),
	Helpers().Neutrons({
		Event = Helpers().Define(
			Helpers().Shell("ProbabilityEvent","an event branch, with a probability on it",
				false,{},{Finished = false}
			),
			Helpers().Nucleus(function(Class: ClassHelper) 
				local self,self_ = Class.self({},{},Helpers.Tree.Node.AsSuper())
				self_.INIT = function(EvtName:string,EvtWeight:number)
					self.Data = {
						Name = EvtName,
						GivenWeight = EvtWeight,
						TrueWeight = 0
					}
					self_().INIT(
						{
							Name = EvtName,
							GivenWeight = EvtWeight,
							TrueWeight = 0
						}
					)
					return self
				end
				
				self.Data = self.Data :: {Name:string,GivenWeight:number,TrueWeight:number}
				self_.Children = self_.Children :: {typeof(self)}
				
				
				return Class.Pack(self,self_)
			end),
			Helpers().Neutrons({})
		)
	})
)
export type ProTree = typeof(Helpers.Discrete.ProbabilityTree.New())
export type Event = typeof(Helpers.Discrete.ProbabilityTree.Event.New())

Helpers.Discrete.ConstrainedIntValue = Helpers().Define(
	Helpers().Shell(
		"IntConstrainer","a class constraining a number between bounds A and B",
		false,
		{},
		{Finished = true, Notes="Works as expected!"}
	),
	Helpers().Nucleus(function(Class: ClassHelper) 
		local self,self_ = Class.self({},{})
		self_.INIT = function(bA:number,bB:number)
			
			self_.Bounds = {
				Start = bA,
				End = bB,
			}
			
			self_.Value = bA
			
			self.Interpolate = function(alpha:number)
				alpha = math.clamp(alpha,0,1)
				local NewValue = (function()
					local lb = self_.Bounds.Start
					local ub = self_.Bounds.End
					local diff = ub - lb -- finds the range of the bounds
					local mult = alpha * diff -- multiplies alpha by the range
					local NewVal = lb + mult -- adds the new alpha value to lb, creating a number inside the 
					return NewVal
				end)()
				self.Set(NewValue)
			end
			
			self.Set = function(NewValue:number) :number
				if not NewValue then 
					self_.Value = math.clamp(
						self_.Value,
						self_.Bounds.Start,
						self_.Bounds.End
					)
				else
					self_.Value = math.clamp(
						NewValue,
						self_.Bounds.Start,
						self_.Bounds.End
					)
				end
			end
			self.Get = function(ValueType:"Identity"|"Complement")
				if ValueType == "Identity" then return self_.Value
				elseif ValueType == "Complement" then
					return self_.Bounds.Start+self_.Bounds.End - self_.Value
				else
					error("No valid Value Type specified.")
				end
			end
			
			self.MoveBound = function(
				bound:"Lower"|"Upper",
				Nv:number
			)
				if bound == "Lower" then
					assert(Nv < self_.Bounds.End,"LowerBound cannot be higher than Current UpperBound")
					self_.Bounds.Start = Nv
				elseif bound == "Upper" then
					assert(Nv > self_.Bounds.Start,"UpperBound cannot be lower than Current LowerBound")
					self_.Bounds.End = Nv
				else
					error("No bound was specified.")
				end
			end
			
			return self
		end
		return Class.Pack(self,self_)
	end),
	Helpers().Neutrons({})
)
export type ConstrainedValue = typeof(Helpers.Discrete.ConstrainedIntValue.New())

CMV6.Factory = function<TBL>(TBL:TBL) : setmetatable<TBL,{__index:typeof(Helpers),__call:()->typeof(FactoryFunctions)}>
	local Fctr = Factory(TBL)
	return setmetatable(Fctr,{__index = Helpers,__call = getmetatable(Fctr).__call})
end



return CMV6
