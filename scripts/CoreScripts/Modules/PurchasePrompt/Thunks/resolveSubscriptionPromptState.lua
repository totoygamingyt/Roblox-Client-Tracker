local Root = script.Parent.Parent
local UserInputService = game:GetService("UserInputService")

local SetPromptState = require(Root.Actions.SetPromptState)
local ErrorOccurred = require(Root.Actions.ErrorOccurred)
local ProductInfoReceived = require(Root.Actions.ProductInfoReceived)
local BalanceInfoRecieved = require(Root.Actions.BalanceInfoRecieved)
local AccountInfoReceived = require(Root.Actions.AccountInfoReceived)
local PromptState = require(Root.Enums.PromptState)
local PurchaseError = require(Root.Enums.PurchaseError)
local UpsellFlow = require(Root.Enums.UpsellFlow)
local getUpsellFlow = require(Root.NativeUpsell.getUpsellFlow)
local PromptNativeUpsell = require(Root.Actions.PromptNativeUpsell)
local selectRobuxProduct = require(Root.NativeUpsell.selectRobuxProduct)
local selectRobuxProductFromProvider = require(Root.NativeUpsell.selectRobuxProductFromProvider)
local getPaymentFromPlatform = require(Root.Utils.getPaymentFromPlatform)
local getHasAmazonUserAgent = require(Root.Utils.getHasAmazonUserAgent)
local Thunk = require(Root.Thunk)

local GetFFlagEnablePPUpsellProductListRefactor = require(Root.Flags.GetFFlagEnablePPUpsellProductListRefactor)
local GetFFlagEnableLuobuInGameUpsell = require(Root.Flags.GetFFlagEnableLuobuInGameUpsell)
local GetFFlagPurchasePromptNotEnoughRobux = require(Root.Flags.GetFFlagPurchasePromptNotEnoughRobux)
local FFlagPPAccountInfoMigration = require(Root.Flags.FFlagPPAccountInfoMigration)

local function resolveSubscriptionPromptState(productInfo, accountInfo, balanceInfo, alreadyOwned)
	return Thunk.new(script.Name, {}, function(store, services)
		store:dispatch(ProductInfoReceived(productInfo))
		store:dispatch(AccountInfoReceived(accountInfo))
		if FFlagPPAccountInfoMigration then
			store:dispatch(BalanceInfoRecieved(balanceInfo))
		end

		if alreadyOwned then
			return store:dispatch(ErrorOccurred(PurchaseError.AlreadyOwn))
		end

		if not productInfo.IsForSale then
			return store:dispatch(ErrorOccurred(PurchaseError.NotForSale))
		end

		local robuxBalance = FFlagPPAccountInfoMigration and balanceInfo.robux or accountInfo.RobuxBalance
		local isPlayerPremium = FFlagPPAccountInfoMigration and accountInfo.isPremium or accountInfo.MembershipType == 4
		local price = productInfo.PriceInRobux or 0
		local platform = UserInputService:GetPlatform()
		local upsellFlow = getUpsellFlow(platform)

		if price > robuxBalance then
			if upsellFlow == UpsellFlow.Unavailable then
				return store:dispatch(ErrorOccurred(PurchaseError.NotEnoughRobuxNoUpsell))
			end

			if upsellFlow == UpsellFlow.Web then
				return store:dispatch(SetPromptState(PromptState.RobuxUpsell))
			else
				local neededRobux = price - robuxBalance

				if GetFFlagEnablePPUpsellProductListRefactor() then
					local isAmazon = getHasAmazonUserAgent()
					local isLuobu = GetFFlagEnableLuobuInGameUpsell()
					local paymentPlatform = getPaymentFromPlatform(platform, isLuobu, isAmazon)
					return selectRobuxProductFromProvider(paymentPlatform, neededRobux, isPlayerPremium, nil):andThen(function(product)
						-- We found a valid upsell product for the current platform
						store:dispatch(PromptNativeUpsell(product.productId, product.robuxValue))
					end, function()
						-- No upsell item will provide sufficient funds to make this purchase
						if GetFFlagPurchasePromptNotEnoughRobux() or platform == Enum.Platform.XBoxOne then
							store:dispatch(ErrorOccurred(PurchaseError.NotEnoughRobuxXbox))
						else
							store:dispatch(ErrorOccurred(PurchaseError.NotEnoughRobux))
						end
					end)
				else
					return selectRobuxProduct(platform, neededRobux, isPlayerPremium)
						:andThen(function(product)
							-- We found a valid upsell product for the current platform
							store:dispatch(PromptNativeUpsell(product.productId, product.robuxValue))
						end, function()
							-- No upsell item will provide sufficient funds to make this purchase
							if GetFFlagPurchasePromptNotEnoughRobux() or platform == Enum.Platform.XBoxOne then
								store:dispatch(ErrorOccurred(PurchaseError.NotEnoughRobuxXbox))
							else
								store:dispatch(ErrorOccurred(PurchaseError.NotEnoughRobux))
							end
						end)
				end
			end
		end

		return store:dispatch(SetPromptState(PromptState.PromptPurchase))
	end)
end

return resolveSubscriptionPromptState
