// SPDX-License-Identifier: GNU GPLv3
pragma solidity >=0.8.2;

// ============================ IAngleGovernance.sol ===============================
// This file contains the interfaces for the main contracts of Angle protocol with just
// the functions governance can play on to change parameters or take the deployment
// of new contracts into account. There are some functions that can be called only by the 
// governor addresses of the protocol and others that can also be called by

/// @notice Interface for the governor functions of the `StableMaster` contract handling all the collateral
/// types accepted for a given stablecoin
interface IStableMaster{

    /// @notice Deploys a new collateral by creating the correct references in the corresponding contracts
    /// @param poolManager Contract managing and storing this collateral for this stablecoin
    /// @param perpetualManager Contract managing HA perpetuals for this stablecoin
    /// @param oracle Reference to the oracle that will give the price of the collateral with respect to the stablecoin
    /// @param sanToken Reference to the sanTokens associated to the collateral
    function deployCollateral(
        IPoolManager poolManager,
        IPerpetualManager perpetualManager,
        IFeeManager feeManager,
        IOracle oracle,
        ISanToken sanToken
    ) external;

    /// @notice Removes a collateral from the list of accepted collateral types and pauses all actions associated
    /// to this collateral
    /// @param poolManager Reference to the contract managing this collateral for this stablecoin in the protocol
    /// @param settlementContract Settlement contract that will be used to close everyone's positions and to let
    /// users, SLPs and HAs redeem if not all a portion of their claim
    /// @dev Since this function has the ability to transfer the contract's funds to another contract, it is
    /// only accessible to the governor
    /// @dev Before calling this function, governance should make sure that all the collateral lent to strategies
    /// has been withdrawn
    function revokeCollateral(IPoolManager poolManager, ICollateralSettler settlementContract) external;

    /// @notice Pauses an agent's actions within this contract for a given collateral type for this stablecoin
    /// @param agent Bytes representing the agent (`SLP` or `STABLE`) and the collateral type that is going to
    /// be paused. To get the `bytes32` from a string, we use in Solidity a `keccak256` function
    /// @param poolManager Reference to the contract managing this collateral for this stablecoin in the protocol and
    /// for which `agent` needs to be paused
    /// @dev If agent is `STABLE`, it is going to be impossible for users to mint stablecoins using collateral or to burn
    /// their stablecoins
    /// @dev If agent is `SLP`, it is going to be impossible for SLPs to deposit collateral and receive
    /// sanTokens in exchange, or to withdraw collateral from their sanTokens
    function pause(bytes32 agent, IPoolManager poolManager) external;

    /// @notice Unpauses an agent's action for a given collateral type for this stablecoin
    /// @param agent Agent (`SLP` or `STABLE`) to unpause the action of
    /// @param poolManager Reference to the associated `PoolManager`
    function unpause(bytes32 agent, IPoolManager poolManager) external;

    /// @notice Updates the `stocksUsers` for a given pair of collateral
    /// @param amount Amount of `stocksUsers` to transfer from a pool to another
    /// @param poolManagerUp Reference to `PoolManager` for which `stocksUsers` needs to increase
    /// @param poolManagerDown Reference to `PoolManager` for which `stocksUsers` needs to decrease
    /// `stocksUsers` is the amount of collateral from users in stablecoin value for this collateral type
    function rebalanceStocksUsers(uint256 amount, IPoolManager poolManagerUp, IPoolManager poolManagerDown) external;

    /// @notice Propagates the change of oracle for one collateral to all the contracts which need to have
    /// the correct oracle reference
    /// @param _oracle New oracle contract for the pair collateral/stablecoin
    /// @param poolManager Reference to the `PoolManager` contract associated to the collateral
    /// @dev Since this function could be used to manipulate oracle prices, it can only be called by a governor
    /// address
    function setOracle(IOracle _oracle, IPoolManager poolManager) external;

    /// @notice Changes the parameter to cap the number of stablecoins you can issue using one
    /// collateral type
    /// @param _capOnStableMinted New cap on the amount of stablecoins you can issue using one 
    /// collateral type
    /// @param poolManager Reference to the `PoolManager` contract associated to the collateral
    function setCapOnStableAndMaxInterests(uint256 _capOnStableMinted, uint256 _maxInterestsDistributed, IPoolManager poolManager) external;

    /// @notice Sets a new `FeeManager` contract and removes the old one which becomes useless
    /// @param newFeeManager New `FeeManager` contract
    /// @param oldFeeManager Old `FeeManager` contract
    /// @param poolManager Reference to the contract managing this collateral for this stablecoin in the protocol
    /// and associated to the `FeeManager` to update
    function setFeeManager(address newFeeManager, address oldFeeManager, IPoolManager poolManager) external;

    /// @notice Sets the proportion of fees from burn/mint of users and the proportion
    /// of lending interests going to SLPs
    /// @param _feesForSLPs New proportion of mint/burn fees going to SLPs
    /// @param _interestsForSLPs New proportion of interests from lending going to SLPs
    function setIncentivesForSLPs( uint64 _feesForSLPs, uint64 _interestsForSLPs, IPoolManager poolManager) external;

    /// @notice Sets the x array (ie ratios between amount covered by HAs and amount to cover)
    /// and the y array (ie values of fees at thresholds) used to compute mint and burn fees for users
    /// @param poolManager Reference to the `PoolManager` handling the collateral
    /// @param _xFee Thresholds of hedge ratios
    /// @param _yFee Values of the fees at thresholds
    /// @param _mint Whether mint fees or burn fees should be updated
    function setUserFees(IPoolManager poolManager, uint64[] memory _xFee, uint64[] memory _yFee, uint8 _mint) external;
}

/// @notice Interface for the governance functions of the contract managing perpetuals
interface IPerpetualManager{
    /// @notice Sets `lockTime` that is the minimum amount of time HAs before which HAs can remove collateral
    /// from the protocol
    /// @param _lockTime New `lockTime` parameter
    function setLockTime(uint64 _lockTime) external;

    /// @notice Changes the maximum leverage authorized (commit/margin) and the maintenance margin under which
    /// perpetuals can be liquidated
    /// @param _maxLeverage New value of the maximum leverage allowed
    /// @param _maintenanceMargin The new maintenance margin
    function setBoundsPerpetual(uint64 _maxLeverage, uint64 _maintenanceMargin) external;

    /// @notice Changes the `rewardsDistribution` associated to this contract
    /// @param _rewardsDistribution Address of the new rewards distributor contract
    function setNewRewardsDistributor(address _rewardsDistribution) external;

    /// @notice Sets the conditions and specifies the duration of the reward distribution
    /// @param _rewardsDuration Duration for the rewards for this contract
    /// @param _rewardsDistribution Address which will give the reward tokens
    function setRewardDistribution(uint256 _rewardsDuration, address _rewardsDistribution) external;

    /// @notice Sets `xHAFees` that is the thresholds of values of the ratio between the what's covered
    /// divided by what's to cover by HAs at which fees will change as well as
    /// `yHAFees` that is the value of the deposit or withdraw fees at threshold
    /// @param _xHAFees Array of the x-axis value for the fees (deposit or withdraw)
    /// @param _yHAFees Array of the y-axis value for the fees (deposit or withdraw)
    /// @param deposit Whether deposit or withdraw fees should be updated
    function setHAFees(uint64[] memory _xHAFees, uint64[] memory _yHAFees, uint8 deposit) external;

    /// @notice Sets the target and limit proportions of collateral from users that can be insured by HAs
    /// @param _targetHAHedge Proportion of collateral from users (in stablecoin value) that HAs should cover
    /// @param _limitHAHedge Proportion of collateral from users (in stablecoin value) above which HAs can 
    /// see their perpetuals cashed out
    function setTargetAndLimitHAHedge(uint64 _targetHAHedge, uint64 _limitHAHedge) external;

    /// @notice Sets the proportion of fees going to the keepers when liquidating a HA perpetual
    /// @param _keeperFeesRatio Proportion to keepers
    /// @dev This proportion should be inferior to `BASE_PARAMS`
    function setKeeperFeesLiquidationRatio(uint64 _keeperFeesRatio) external;

    /// @notice Sets the maximum amounts going to the keepers when cashing out perpetuals
    /// because too much was covered by HAs or liquidating a perpetual
    /// @param _keeperFeesLiquidationCap Maximum reward going to the keeper liquidating a perpetual
    /// @param _keeperFeesClosingCap Maximum reward going to the keeper forcing the closing of an ensemble
    /// of perpetuals
    function setKeeperFeesCap(uint256 _keeperFeesLiquidationCap, uint256 _keeperFeesClosingCap) external;

    /// @notice Sets the x-array (ie thresholds) for `FeeManager` when cashing out perpetuals and the y-array that is the
    /// value of the proportions of the fees going to keepers cashing out perpetuals
    /// @param _xKeeperFeesClosing Thresholds for closing fees going to keepers
    /// @param _yKeeperFeesClosing Value of the fees at the different threshold values specified in `xKeeperFeesClosing`
    function setKeeperFeesClosing(uint64[] memory _xKeeperFeesClosing, uint64[] memory _yKeeperFeesClosing) external;

    /// @notice Supports recovering LP Rewards from other systems
    /// @param tokenAddress Address of the token to transfer
    /// @param to Address to give tokens to
    /// @param tokenAmount Amount of tokens to transfer
    function recoverERC20(address tokenAddress,address to, uint256 tokenAmount) external;

    /// @notice Pauses the `getReward` method as well as the functions allowing to create, modify or cash-out perpetuals
    /// @dev After calling this function, it is going to be impossible for HAs to interact with their perpetuals
    /// or claim their rewards on it
    function pause() external;

    /// @notice Unpauses HAs functions
    function unpause() external;
}

/// @notice Interface for the governance functions of the contract managing the collateral of a given
/// collateral/stablecoin pair
interface IPoolManager{
    /// @notice Allows to recover any ERC20 token, including the token handled by this contract, and to send it
    /// to a contract
    /// @param tokenAddress Address of the token to recover
    /// @param to Address of the contract to send collateral to
    /// @param amountToRecover Amount of collateral to transfer
    /// @dev This function can obviously just be called by governance since it has the ability to withdraw funds
    /// from the protocol
    function recoverERC20(address tokenAddress, address to, uint256 amountToRecover) external;

    /// @notice Adds a strategy to the `PoolManager`
    /// @param strategy The address of the strategy to add
    /// @param _debtRatio The share of the total assets that the strategy has access to
    function addStrategy(address strategy, uint256 _debtRatio) external;

    /// @notice Modifies the funds a strategy has access to
    /// @param strategy The address of the Strategy
    /// @param _debtRatio The share of the total assets that the strategy has access to
    /// @dev The update has to be such that the `debtRatio` does not exceeds the 100% threshold
    /// as this `PoolManager` cannot lend collateral that it doesn't not own.
    function updateStrategyDebtRatio(address strategy, uint256 _debtRatio) external;

    /// @notice Triggers an emergency exit for a strategy and then harvests it to fetch all the funds
    /// @param strategy The address of the `Strategy`
    function setStrategyEmergencyExit(address strategy) external;

    /// @notice Revokes a strategy
    /// @param strategy The address of the strategy to revoke
    /// @dev This should only be called after the following happened in order: the `strategy.debtRatio` has been set to 0,
    /// `harvest` has been called enough times to recover all capital gain/losses.
    function revokeStrategy(address strategy) external;

    /// @notice Withdraws a given amount from a strategy, may not recover all funds (see angle-core implementation)
    /// @param strategy The address of the strategy
    /// @param amount The amount to withdraw
    function withdrawFromStrategy(IStrategy strategy, uint256 amount) external;
}

/// @notice Interface for the governance functions of a `Strategy` contract
interface IStrategy{
    /// @notice Used to change `rewards`.
    /// @param _rewards The address to use for pulling rewards.
    function setRewards(IERC20 _rewards) external;

    /// @notice Used to change the reward amount
    /// @param amount The new amount of reward given to keepers
    function setRewardAmount(uint256 amount) external;

    /// @notice Used to change `minReportDelay`. `minReportDelay` is the minimum number
    /// of blocks that should pass for `harvest()` to be called.
    /// @param _delay The minimum number of seconds to wait between harvests.
    function setMinReportDelay(uint256 _delay) external;

    /// @notice Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
    /// of blocks that should pass for `harvest()` to be called.
    /// @param _delay The maximum number of seconds to wait between harvests.
    function setMaxReportDelay(uint256 _delay) external;

    /// @notice Used to change `profitFactor`. `profitFactor` is used to determine
    /// if it's worthwhile to harvest, given gas costs.
    /// @param _profitFactor A ratio to multiply anticipated
    function setProfitFactor(uint256 _profitFactor) external;

    /// @notice Sets how far the Strategy can go into loss without a harvest and report
    /// being required.
    /// @param _debtThreshold How big of a loss this Strategy may carry without
    function setDebtThreshold(uint256 _debtThreshold) external;

    /// @notice Removes tokens from this Strategy that are not the type of tokens
    /// managed by this Strategy. This may be used in case of accidentally
    /// sending the wrong kind of token to this Strategy.
    /// @param _token The token to transfer out of this `PoolManager`.
    /// @param to Address to send the tokens to.
    function sweep(address _token, address to) external;
}


/// @notice Interface for the `RewardsDistributor` contract: this contract is responsible for interacting with all the
/// staking contracts and for distributing them the reward token (most often ANGLE) given to stakers
interface IRewardsDistributor {
    /// @notice Sends tokens back to governance treasury or another address
    /// @param amount Amount of tokens to send back to treasury
    /// @param to Address to send the tokens to
    function governorWithdrawRewardToken(uint256 amount, address to) external;

    /// @notice Function to withdraw ERC20 tokens that could accrue on a staking contract
    /// @param tokenAddress Address of the ERC20 to recover
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @param stakingContract Reference to the staking contract
    function governorRecover(
        address tokenAddress,
        address to,
        uint256 amount,
        IStakingRewards stakingContract
    ) external;

    /// @notice Sets a new rewards distributor contract and automatically makes this contract useless
    /// @param newRewardsDistributor Address of the new rewards distributor contract
    function setNewRewardsDistributor(address newRewardsDistributor) external;

    /// @notice Deletes a staking contract from the staking contract map and removes it from the
    /// `stakingContractsList`
    /// @param stakingContract Contract to remove
    function removeStakingContract(IStakingRewards stakingContract) external;

    /// @notice Notifies and initializes a new staking contract
    /// @param _stakingContract Address of the staking contract
    /// @param _duration Time frame during which tokens will be distributed
    /// @param _incentiveAmount Incentive amount given to keepers calling the update function
    /// @param _updateFrequency Frequency when it is possible to call the update function and give tokens to the staking contract
    /// @param _amountToDistribute Amount of gov tokens to give to the staking contract across all drips
    function setStakingContract(
        address _stakingContract,
        uint256 _duration,
        uint256 _incentiveAmount,
        uint256 _updateFrequency,
        uint256 _amountToDistribute
    ) external;

    /// @notice Sets the update frequency
    /// @param _updateFrequency New update frequency
    /// @param stakingContract Reference to the staking contract
    function setUpdateFrequency(uint256 _updateFrequency, IStakingRewards stakingContract) external;

    /// @notice Sets the incentive amount for calling drip
    /// @param _incentiveAmount New incentive amount
    /// @param stakingContract Reference to the staking contract
    function setIncentiveAmount(uint256 _incentiveAmount, IStakingRewards stakingContract) external;

    /// @notice Sets the new amount to distribute to a staking contract
    /// @param _amountToDistribute New amount to distribute
    /// @param stakingContract Reference to the staking contract
    function setAmountToDistribute(uint256 _amountToDistribute, IStakingRewards stakingContract) external;

    /// @notice Sets the new duration with which tokens will be distributed to the staking contract
    /// @param _duration New duration
    /// @param stakingContract Reference to the staking contract
    function setDuration(uint256 _duration, IStakingRewards stakingContract) external;
}

/// @notice Interface for the governance functions of the `BondingCurve` contract
/// @dev Bonding Curve used to buy governance tokens directly to the protocol
interface IBondingCurve {
    /// @notice Transfers tokens from the bonding curve to another address
    /// @param tokenAddress Address of the token to recover
    /// @param amountToRecover Amount of tokens to transfer
    /// @param to Destination address
    function recoverERC20(address tokenAddress, address to, uint256 amountToRecover) external;

    /// @notice Allows a new stablecoin
    /// @param _agToken Reference to the agToken
    /// @param _oracle Reference to the oracle that will be used to have the price of this stablecoin in reference
    /// @param _isReference Whether this stablecoin will be the reference for oracles
    /// @dev To set a new reference coin, the old reference must have been revoked before
    /// @dev Calling this function for a stablecoin that already exists will just change its oracle if the
    /// agToken was already reference, and also set a new reference if the coin was already existing
    function allowNewStablecoin(IAgToken _agToken, IOracle _oracle, uint256 _isReference) external;

    /// @notice Changes the oracle associated to a stablecoin
    /// @param _agToken Reference to the agToken
    /// @param _oracle Reference to the oracle that will be used to have the price of this stablecoin in reference
    /// @dev Oracle contract should be done with respect to reference
    function changeOracle(IAgToken _agToken, IOracle _oracle) external;

    /// @notice Revokes a stablecoin as a medium of payment
    /// @param _agToken Reference to the agToken
    function revokeStablecoin(IAgToken _agToken) external;

    /// @notice Changes the start price (in reference)
    /// @param _startPrice New start price for the formula
    /// @dev This function may be useful to help re-collateralize the protocol in case of distress
    /// as it could allow to buy governance tokens at a discount
    function changeStartPrice(uint256 _startPrice) external;

    /// @notice Changes the total amount of tokens that can be sold with the bonding curve
    /// @param _totalTokensToSell New total amount of tokens to sell
    function changeTokensToSell(uint256 _totalTokensToSell) external ;

    /// @notice Pauses the possibility to buy `soldToken` from the contract
    function pause() external ;

    /// @notice Unpauses and reactivates the possibility to buy tokens from the contract
    function unpause() external ;
}

/// @notice Interface for the governance functions of collateral settlement contracts
interface ICollateralSettler {
    /// @notice Changes the amount that can be redistributed with this contract
    /// @param newAmountToRedistribute New amount that can be given by this contract
    /// @dev This function should typically be called after the settlement trigger and after this contract
    /// receives more collateral
    function setAmountToRedistribute(uint256 newAmountToRedistribute) external;

    /// @notice Recovers leftover tokens from the contract or tokens that were mistakenly sent to the contract
    /// @param tokenAddress Address of the token to recover
    /// @param to Address to send the remaining tokens to
    /// @param amountToRecover Amount to recover from the contract
    /// @dev It can be used after the `setAmountToDistributeEach` function has been called to allocate
    /// the surplus of the contract elsewhere
    /// @dev It can also be used to recover tokens that are mistakenly sent to this contract
    function recoverERC20(address tokenAddress, address to, uint256 amountToRecover) external;

    /// @notice Changes the governance tokens proportionality ratio used to compute the claims
    /// with governance tokens
    /// @param _proportionalRatioGovUser New ratio for users
    /// @param _proportionalRatioGovLP New ratio for LPs (both SLPs and HAs)
    /// @dev This function can only be called before the claim period and settlement trigger: there could be
    /// a governance attack if these ratios can be modified during the claim period
    function setProportionalRatioGov(uint64 _proportionalRatioGovUser, uint64 _proportionalRatioGovLP) external;

    /// @notice Pauses pausable methods, that is all the claim and redeem methods
    function pause() external;

    /// @notice Unpauses paused methods
    function unpause() external;
}


/// @notice Interface for the `Core` contract of the protocol: this is the contract making sure that governance
/// remains the same at the protocol level and that maintains the integrity of the protocol
interface ICore {
    /// @notice Changes the `Core` contract of the protocol
    /// @param newCore Address of the new `Core` contract
    function setCore(ICore newCore) external;

    /// @notice Adds a new stablecoin to the system
    /// @param agToken Address of the new `AgToken` contract
    /// @dev To maintain consistency, the address of the `StableMaster` contract corresponding to the
    /// `AgToken` is automatically retrieved
    /// @dev The `StableMaster` receives the reference to the governor and guardian addresses of the protocol
    /// @dev The `AgToken` and `StableMaster` contracts should have previously been initialized with correct references
    /// in it, with for the `StableMaster` a reference to the `Core` contract and for the `AgToken` a reference to the
    /// `StableMaster`
    /// @dev The call to the `deploy` function of the `stableMaster` will revert if the `stableMaster` has not been
    /// initialized with the correct `core` address
    function deployStableMaster(address agToken) external;

    /// @notice Revokes a `StableMaster` contract
    /// @param stableMaster Address of  the `StableMaster` to revoke
    /// @dev This function just removes a `StableMaster` contract from the `stablecoinList`
    /// @dev The consequence is that the `StableMaster` contract will no longer be affected by changes in
    /// governor or guardian occuring from the protocol
    /// @dev This function is mostly here to clean the mappings and save some storage space
    function revokeStableMaster(address stableMaster) external;


    // =============================== Disclaimer ==============================
    // The following functions do not propagate the changes they induce to some bricks of the protocol
    // like the `CollateralSettler`, the `BondingCurve`, the staking and rewards distribution contracts
    // and the oracle contracts using Uniswap. Governance should be wary when calling these functions and
    // make equivalent changes in these contracts to maintain consistency at the scale of the protocol

    /// @notice Adds a new governor address
    /// @param _governor New governor address
    /// @dev This function propagates the new governor role across most contracts of the protocol (except the above disclaimer)
    /// @dev Governor is also guardian everywhere in all contracts
    function addGovernor(address _governor) external;

    /// @notice Removes a governor address
    /// @param _governor Governor address to remove
    /// @dev There must always be one governor in the protocol
    function removeGovernor(address _governor) external;

    /// @notice Changes the guardian address
    /// @param _newGuardian New guardian address
    /// @dev Guardian is able to change by itself the address corresponding to its role
    /// @dev There can only be one guardian address in the protocol
    /// @dev The guardian address cannot be a governor address
    function setGuardian(address _newGuardian) external;

    /// @notice Revokes the guardian address
    /// @dev Guardian is able to auto-revoke itself
    /// @dev There can only be one `guardian` address in the protocol
    function revokeGuardian() external;
}

/// @notice Interface for the `FeeManager` contract: this is the contract that keepers should call to update the fees
/// for users and HAs depending on the collateral ratio
interface IFeeManager {
    /// @notice Sets the x(ie thresholds of collateral ratio) array / y(ie value of fees at threshold)-array
    /// for users minting, burning, for SLPs withdrawal slippage or for the slippage fee when updating
    /// the exchange rate between sanTokens and collateral
    /// @param xArray New collateral ratio thresholds (in ascending order)
    /// @param yArray New fees or values for the parameters at thresholds
    /// @param typeChange Type of parameter to change
    /// @dev For `typeChange = 1`, `bonusMalusMint` fees are updated
    /// @dev For `typeChange = 2`, `bonusMalusBurn` fees are updated
    /// @dev For `typeChange = 3`, `slippage` values are updated
    /// @dev For other values of `typeChange`, `slippageFee` values are updated
    function setFees(uint256[] memory xArray, uint64[] memory yArray, uint8 typeChange) external;

    /// @notice Sets the extra fees that can be used when HAs deposit or withdraw collateral from the
    /// protocol
    /// @param _haFeeDeposit New parameter to modify deposit fee for HAs
    /// @param _haFeeWithdraw New parameter to modify withdraw fee for HAs
    function setHAFees(uint64 _haFeeDeposit, uint64 _haFeeWithdraw) external;
}


/// @notice Oracle contract, one contract is deployed per collateral/stablecoin pair
/// @dev This contract concerns an oracle that only uses both Chainlink and Uniswap for multiple pools
/// @dev For oracle contracts that use Uniswap, we can change the TWAP period
interface IOracleMulti{
    /// @notice Changes the TWAP period
    /// @param _twapPeriod New window to compute the TWAP
    function changeTwapPeriod(uint32 _twapPeriod) external;
}

interface IAgToken {}

interface IOracle {}

interface IERC20 {}

interface IStakingRewards {}

interface ISanToken {}
