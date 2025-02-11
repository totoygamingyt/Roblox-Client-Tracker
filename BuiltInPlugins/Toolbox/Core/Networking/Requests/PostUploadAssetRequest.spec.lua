return function()
	local Plugin = script.Parent.Parent.Parent.Parent


	local Packages = Plugin.Packages

	local Rodux = require(Packages.Rodux)
	local Framework = require(Packages.Framework)

	local NetworkInterfaceMock = require(Plugin.Core.Networking.NetworkInterfaceMock)
	local PostUploadAssetRequest = require(Plugin.Core.Networking.Requests.PostUploadAssetRequest)
	local AssetConfigReducer = require(Plugin.Core.Reducers.AssetConfigReducer)

	local CoreTestUtils = require(Plugin.TestUtils.CoreTestUtils)
	local Promise = Framework.Util.Promise

	it("should successfully upload an animation", function()
		local networkInterfaceMock = NetworkInterfaceMock.new()

		local middleware = CoreTestUtils.createThunkMiddleware()

		local store = Rodux.Store.new(AssetConfigReducer, nil, middleware)

		-- Page 1
		local stubCalled = false
		networkInterfaceMock.postUploadAsset =
			function(
				self,
				assetId,
				assetType,
				name,
				description,
				genreTypeID,
				isPublicOverride,
				commentOn,
				groupId,
				fileDataString
			)
				stubCalled = true

				expect(assetId).to.equal(0)
				expect(name).to.equal("Test!")
				assert(string.len(fileDataString) > 0)

				return Promise.resolve({
					responseBody = "123",
				})
			end

		local model = Instance.new("Model")
		model.Parent = game.Workspace

		local publishInfo = {
			networkInterface = networkInterfaceMock,
			assetId = 0,
			name = "Test!",
			groupId = nil,
			instances = { model },
		}

		store:dispatch(PostUploadAssetRequest(publishInfo)):await()

		expect(stubCalled).to.equal(true)
		expect(store:getState().uploadSucceeded).to.equal(true)
		expect(store:getState().assetId).to.equal("123")

		model:Destroy()
	end)
end
