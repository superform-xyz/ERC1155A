namespace SuperERC1155s.Contracts.PositionsSplitter.ContractDefinition

open System
open System.Threading.Tasks
open System.Collections.Generic
open System.Numerics
open Nethereum.Hex.HexTypes
open Nethereum.ABI.FunctionEncoding.Attributes
open Nethereum.RPC.Eth.DTOs
open Nethereum.Contracts.CQS
open Nethereum.Contracts
open System.Threading

    
    
    type PositionsSplitterDeployment(byteCode: string) =
        inherit ContractDeploymentMessage(byteCode)
        
        static let BYTECODE = ""
        
        new() = PositionsSplitterDeployment(BYTECODE)
        

        
    
    [<Function("onERC1155BatchReceived", "bytes4")>]
    type OnERC1155BatchReceivedFunction() = 
        inherit FunctionMessage()
    
            [<Parameter("address", "operator", 1)>]
            member val public Operator = Unchecked.defaultof<string> with get, set
            [<Parameter("address", "from", 2)>]
            member val public From = Unchecked.defaultof<string> with get, set
            [<Parameter("uint256[]", "ids", 3)>]
            member val public Ids = Unchecked.defaultof<List<BigInteger>> with get, set
            [<Parameter("uint256[]", "values", 4)>]
            member val public Values = Unchecked.defaultof<List<BigInteger>> with get, set
            [<Parameter("bytes", "data", 5)>]
            member val public Data = Unchecked.defaultof<byte[]> with get, set
        
    
    [<Function("onERC1155Received", "bytes4")>]
    type OnERC1155ReceivedFunction() = 
        inherit FunctionMessage()
    
            [<Parameter("address", "operator", 1)>]
            member val public Operator = Unchecked.defaultof<string> with get, set
            [<Parameter("address", "from", 2)>]
            member val public From = Unchecked.defaultof<string> with get, set
            [<Parameter("uint256", "id", 3)>]
            member val public Id = Unchecked.defaultof<BigInteger> with get, set
            [<Parameter("uint256", "value", 4)>]
            member val public Value = Unchecked.defaultof<BigInteger> with get, set
            [<Parameter("bytes", "data", 5)>]
            member val public Data = Unchecked.defaultof<byte[]> with get, set
        
    
    [<Function("registerWrapper", "address")>]
    type RegisterWrapperFunction() = 
        inherit FunctionMessage()
    
            [<Parameter("uint256", "id", 1)>]
            member val public Id = Unchecked.defaultof<BigInteger> with get, set
            [<Parameter("string", "name", 2)>]
            member val public Name = Unchecked.defaultof<string> with get, set
            [<Parameter("string", "symbol", 3)>]
            member val public Symbol = Unchecked.defaultof<string> with get, set
            [<Parameter("uint8", "decimals", 4)>]
            member val public Decimals = Unchecked.defaultof<byte> with get, set
        
    
    [<Function("sERC1155", "address")>]
    type SERC1155Function() = 
        inherit FunctionMessage()
    

        
    
    [<Function("synthethicTokenId", "address")>]
    type SynthethicTokenIdFunction() = 
        inherit FunctionMessage()
    
            [<Parameter("uint256", "id", 1)>]
            member val public Id = Unchecked.defaultof<BigInteger> with get, set
        
    
    [<Function("syntheticTokenID", "uint256")>]
    type SyntheticTokenIDFunction() = 
        inherit FunctionMessage()
    

        
    
    [<Function("unwrap")>]
    type UnwrapFunction() = 
        inherit FunctionMessage()
    
            [<Parameter("uint256", "id", 1)>]
            member val public Id = Unchecked.defaultof<BigInteger> with get, set
            [<Parameter("uint256", "amount", 2)>]
            member val public Amount = Unchecked.defaultof<BigInteger> with get, set
        
    
    [<Function("wrap")>]
    type WrapFunction() = 
        inherit FunctionMessage()
    
            [<Parameter("uint256", "id", 1)>]
            member val public Id = Unchecked.defaultof<BigInteger> with get, set
            [<Parameter("uint256", "amount", 2)>]
            member val public Amount = Unchecked.defaultof<BigInteger> with get, set
        
    
    [<Function("wrapBatch")>]
    type WrapBatchFunction() = 
        inherit FunctionMessage()
    
            [<Parameter("uint256[]", "ids", 1)>]
            member val public Ids = Unchecked.defaultof<List<BigInteger>> with get, set
            [<Parameter("uint256[]", "amounts", 2)>]
            member val public Amounts = Unchecked.defaultof<List<BigInteger>> with get, set
        
    
    [<Event("Unwrapped")>]
    type UnwrappedEventDTO() =
        inherit EventDTO()
            [<Parameter("address", "user", 1, false )>]
            member val User = Unchecked.defaultof<string> with get, set
            [<Parameter("uint256", "id", 2, false )>]
            member val Id = Unchecked.defaultof<BigInteger> with get, set
            [<Parameter("uint256", "amount", 3, false )>]
            member val Amount = Unchecked.defaultof<BigInteger> with get, set
        
    
    [<Event("UnwrappedBatch")>]
    type UnwrappedBatchEventDTO() =
        inherit EventDTO()
            [<Parameter("address", "user", 1, false )>]
            member val User = Unchecked.defaultof<string> with get, set
            [<Parameter("uint256[]", "ids", 2, false )>]
            member val Ids = Unchecked.defaultof<List<BigInteger>> with get, set
            [<Parameter("uint256[]", "amounts", 3, false )>]
            member val Amounts = Unchecked.defaultof<List<BigInteger>> with get, set
        
    
    [<Event("Wrapped")>]
    type WrappedEventDTO() =
        inherit EventDTO()
            [<Parameter("address", "user", 1, false )>]
            member val User = Unchecked.defaultof<string> with get, set
            [<Parameter("uint256", "id", 2, false )>]
            member val Id = Unchecked.defaultof<BigInteger> with get, set
            [<Parameter("uint256", "amount", 3, false )>]
            member val Amount = Unchecked.defaultof<BigInteger> with get, set
        
    
    [<Event("WrappedBatch")>]
    type WrappedBatchEventDTO() =
        inherit EventDTO()
            [<Parameter("address", "user", 1, false )>]
            member val User = Unchecked.defaultof<string> with get, set
            [<Parameter("uint256[]", "ids", 2, false )>]
            member val Ids = Unchecked.defaultof<List<BigInteger>> with get, set
            [<Parameter("uint256[]", "amounts", 3, false )>]
            member val Amounts = Unchecked.defaultof<List<BigInteger>> with get, set
        
    
    [<FunctionOutput>]
    type OnERC1155BatchReceivedOutputDTO() =
        inherit FunctionOutputDTO() 
            [<Parameter("bytes4", "", 1)>]
            member val public ReturnValue1 = Unchecked.defaultof<byte[]> with get, set
        
    
    [<FunctionOutput>]
    type OnERC1155ReceivedOutputDTO() =
        inherit FunctionOutputDTO() 
            [<Parameter("bytes4", "", 1)>]
            member val public ReturnValue1 = Unchecked.defaultof<byte[]> with get, set
        
    
    
    
    [<FunctionOutput>]
    type SERC1155OutputDTO() =
        inherit FunctionOutputDTO() 
            [<Parameter("address", "", 1)>]
            member val public ReturnValue1 = Unchecked.defaultof<string> with get, set
        
    
    [<FunctionOutput>]
    type SynthethicTokenIdOutputDTO() =
        inherit FunctionOutputDTO() 
            [<Parameter("address", "", 1)>]
            member val public ReturnValue1 = Unchecked.defaultof<string> with get, set
        
    
    [<FunctionOutput>]
    type SyntheticTokenIDOutputDTO() =
        inherit FunctionOutputDTO() 
            [<Parameter("uint256", "", 1)>]
            member val public ReturnValue1 = Unchecked.defaultof<BigInteger> with get, set
        
    
    
    
    
    


