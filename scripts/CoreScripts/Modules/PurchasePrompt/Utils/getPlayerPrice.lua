-- Used on the data in the state
return function(productInfo, isPlayerPremium)
	if isPlayerPremium then
		if productInfo.premiumPrice ~= nil then
			return productInfo.premiumPrice
		else
			return productInfo.price
		end
	else
		return productInfo.price
	end
end
