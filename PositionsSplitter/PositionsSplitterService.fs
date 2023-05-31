namespace SuperERC1155s.Contracts.PositionsSplitter

open System
open System.Threading.Tasks
open System.Collections.Generic
open System.Numerics
open Nethereum.Hex.HexTypes
open Nethereum.ABI.FunctionEncoding.Attributes
open Nethereum.Web3
open Nethereum.RPC.Eth.DTOs
open Nethereum.Contracts.CQS
open Nethereum.Contracts.ContractHandlers
open Nethereum.Contracts
open System.Threading
open SuperERC1155s.Contracts.PositionsSplitter.ContractDefinition


    type PositionsSplitterService (web3: Web3, contractAddress: string) =
    
        member val Web3 = web3 with get
        member val ContractHandler = web3.Eth.GetContractHandler(contractAddress) with get
    
        static member DeployContractAndWaitForReceiptAsync(web3: Web3, positionsSplitterDeployment: PositionsSplitterDeployment, ?cancellationTokenSource : CancellationTokenSource): Task<TransactionReceipt> = 
            let cancellationTokenSourceVal = defaultArg cancellationTokenSource null
            web3.Eth.GetContractDeploymentHandler<PositionsSplitterDeployment>().SendRequestAndWaitForReceiptAsync(positionsSplitterDeployment, cancellationTokenSourceVal)
        
        static member DeployContractAsync(web3: Web3, positionsSplitterDeployment: PositionsSplitterDeployment): Task<string> =
            web3.Eth.GetContractDeploymentHandler<PositionsSplitterDeployment>().SendRequestAsync(positionsSplitterDeployment)
        
        static member DeployContractAndGetServiceAsync(web3: Web3, positionsSplitterDeployment: PositionsSplitterDeployment, ?cancellationTokenSource : CancellationTokenSource) = async {
            let cancellationTokenSourceVal = defaultArg cancellationTokenSource null
            let! receipt = PositionsSplitterService.DeployContractAndWaitForReceiptAsync(web3, positionsSplitterDeployment, cancellationTokenSourceVal) |> Async.AwaitTask
            return new PositionsSplitterService(web3, receipt.ContractAddress);
            }
    
        member this.OnERC1155BatchReceivedQueryAsync(onERC1155BatchReceivedFunction: OnERC1155BatchReceivedFunction, ?blockParameter: BlockParameter): Task<byte[]> =
            let blockParameterVal = defaultArg blockParameter null
            this.ContractHandler.QueryAsync<OnERC1155BatchReceivedFunction, byte[]>(onERC1155BatchReceivedFunction, blockParameterVal)
            
        member this.OnERC1155ReceivedQueryAsync(onERC1155ReceivedFunction: OnERC1155ReceivedFunction, ?blockParameter: BlockParameter): Task<byte[]> =
            let blockParameterVal = defaultArg blockParameter null
            this.ContractHandler.QueryAsync<OnERC1155ReceivedFunction, byte[]>(onERC1155ReceivedFunction, blockParameterVal)
            
        member this.RegisterWrapperRequestAsync(registerWrapperFunction: RegisterWrapperFunction): Task<string> =
            this.ContractHandler.SendRequestAsync(registerWrapperFunction);
        
        member this.RegisterWrapperRequestAndWaitForReceiptAsync(registerWrapperFunction: RegisterWrapperFunction, ?cancellationTokenSource : CancellationTokenSource): Task<TransactionReceipt> =
            let cancellationTokenSourceVal = defaultArg cancellationTokenSource null
            this.ContractHandler.SendRequestAndWaitForReceiptAsync(registerWrapperFunction, cancellationTokenSourceVal);
        
        member this.SERC1155QueryAsync(sERC1155Function: SERC1155Function, ?blockParameter: BlockParameter): Task<string> =
            let blockParameterVal = defaultArg blockParameter null
            this.ContractHandler.QueryAsync<SERC1155Function, string>(sERC1155Function, blockParameterVal)
            
        member this.SynthethicTokenIdQueryAsync(synthethicTokenIdFunction: SynthethicTokenIdFunction, ?blockParameter: BlockParameter): Task<string> =
            let blockParameterVal = defaultArg blockParameter null
            this.ContractHandler.QueryAsync<SynthethicTokenIdFunction, string>(synthethicTokenIdFunction, blockParameterVal)
            
        member this.SyntheticTokenIDQueryAsync(syntheticTokenIDFunction: SyntheticTokenIDFunction, ?blockParameter: BlockParameter): Task<BigInteger> =
            let blockParameterVal = defaultArg blockParameter null
            this.ContractHandler.QueryAsync<SyntheticTokenIDFunction, BigInteger>(syntheticTokenIDFunction, blockParameterVal)
            
        member this.UnwrapRequestAsync(unwrapFunction: UnwrapFunction): Task<string> =
            this.ContractHandler.SendRequestAsync(unwrapFunction);
        
        member this.UnwrapRequestAndWaitForReceiptAsync(unwrapFunction: UnwrapFunction, ?cancellationTokenSource : CancellationTokenSource): Task<TransactionReceipt> =
            let cancellationTokenSourceVal = defaultArg cancellationTokenSource null
            this.ContractHandler.SendRequestAndWaitForReceiptAsync(unwrapFunction, cancellationTokenSourceVal);
        
        member this.WrapRequestAsync(wrapFunction: WrapFunction): Task<string> =
            this.ContractHandler.SendRequestAsync(wrapFunction);
        
        member this.WrapRequestAndWaitForReceiptAsync(wrapFunction: WrapFunction, ?cancellationTokenSource : CancellationTokenSource): Task<TransactionReceipt> =
            let cancellationTokenSourceVal = defaultArg cancellationTokenSource null
            this.ContractHandler.SendRequestAndWaitForReceiptAsync(wrapFunction, cancellationTokenSourceVal);
        
        member this.WrapBatchRequestAsync(wrapBatchFunction: WrapBatchFunction): Task<string> =
            this.ContractHandler.SendRequestAsync(wrapBatchFunction);
        
        member this.WrapBatchRequestAndWaitForReceiptAsync(wrapBatchFunction: WrapBatchFunction, ?cancellationTokenSource : CancellationTokenSource): Task<TransactionReceipt> =
            let cancellationTokenSourceVal = defaultArg cancellationTokenSource null
            this.ContractHandler.SendRequestAndWaitForReceiptAsync(wrapBatchFunction, cancellationTokenSourceVal);
        
    

