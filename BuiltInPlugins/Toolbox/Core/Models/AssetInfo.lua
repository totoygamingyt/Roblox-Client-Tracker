--!strict
local FFlagToolboxPackagesInAssetTile = game:GetFastFlag("ToolboxPackagesInAssetTile")
local FFlagToolboxInsertMaterialsInMS = game:GetFastFlag("ToolboxInsertMaterialsInMS")

local Plugin = if FFlagToolboxPackagesInAssetTile then nil else script:FindFirstAncestor("Toolbox") -- unused variable, remove with FFlagToolboxPackagesInAssetTile

export type AudioDetails = {
	Type: string?,
	Artist: string?,
	MusicAlbum: string?,
	MusicGenre: string?,
	SoundEffectCategory: string?,
	SoundEffectSubcategory: string?,
}

export type AssetInfoDetails = {
	Id: number, -- the asset id
	Name: string, -- the asset name
	TypeId: number, -- the assetType id
	AssetGenres: any, -- a list of genres the asset belongs to
	AssetSubTypes: { number }, -- a list of asset subTypes the asset is categorized under | added with FFlagToolboxPackagesInAssetTile
	IsEndorsed: boolean, -- whether or not the asset is endorsed
	Description: string, -- the asset description
	Duration: string?, -- the duration of an audio asset. Only audio assets have this field.
	Created: string?, -- the date in which the asset was created
	Updated: string?, -- the date in which the asset was updated
	HasScripts: boolean, -- whether or not the asset has scripts
}

export type NewAssetInfoDetails = {
	Id: number, -- the asset id
	Name: string, -- the asset name
	TypeId: (boolean | number)?, -- the assetType id
	AssetGenres: any, -- a list of genres the asset belongs to
	Description: string, -- the asset description
	Status: any,
}

export type AssetInfoContext = {
	page: number,
	pagePosition: number,
	position: number,
}

export type AssetInfoCreator = {
	Id: number, -- the creator id
	Name: string, -- the creator name
	Type: string, -- the creator type, such as User or Group
	IsVerifiedCreator: boolean?, -- whether the creator of the asset is verified
}

export type AssetInfoProduct = {
	ProductId: number, -- the product id of the asset
	Price: number, -- the price of the asset
}

export type AssetInfoThumbnail = {
	Final: boolean, -- whether or not the thumbnail has been finalized for retry purposes
	Url: string, -- the thumbnail url
	RetryUrl: string, -- the url to call for a retry
	UserId: number, -- the userId
	EndpointType: string, -- the type of endpoint
}

export type AssetInfoVoting = {
	ShowVotes: boolean, -- whether or not to show votes
	UpVotes: number, -- the number of upvotes
	DownVotes: number, -- the number of downVotes
	VoteCount: number, -- the number of legitimate upvotes + downvotes
	UpVotePercent: number, -- legitimate upvotes / total legit votes
	CanVote: boolean, -- whether or not the user can vote
	UserVote: string, -- the user's vote
	HasVoted: boolean, -- whethr or not the user voted
	ReasonForNotVoteable: string, -- the reason why the user cannot vote
}

export type AssetInfo = {
	-- TODO STM-151: Apparently this union is to make fromCreationsDetails work, it doesn't get the full asset details. To remove this we'd need to refactor fromCreationsDetails usage
	Asset: (AssetInfoDetails | NewAssetInfoDetails)?,
	Context: AssetInfoContext?,
	Creator: AssetInfoCreator?,
	Product: AssetInfoProduct?,
	Thumbnail: AssetInfoThumbnail?,
	Voting: AssetInfoVoting?,
	AudioDetails: AudioDetails?,
}

local AssetInfo = {}

AssetInfo.new = function(): AssetInfo
	return {}
end

function AssetInfo.fromItemDetailsRequest(data): AssetInfo
	local result = AssetInfo.new()
	if data.asset then
		result.Asset = {
			Id = data.asset.id,
			Name = data.asset.name,
			TypeId = data.asset.typeId,
			AssetGenres = data.asset.assetGenres,
			AssetSubTypes = if FFlagToolboxPackagesInAssetTile or FFlagToolboxInsertMaterialsInMS then data.asset.assetSubTypes else nil,
			IsEndorsed = data.asset.isEndorsed,
			Description = data.asset.description,
			Duration = data.asset.duration,
			Created = data.asset.createdUtc,
			Updated = data.asset.updatedUtc,
			HasScripts = data.asset.hasScripts,
		}

		if data.asset.audioDetails then
			result.AudioDetails = {
				Type = data.asset.audioDetails.audioType,
				Artist = data.asset.audioDetails.artist,
				MusicAlbum = data.asset.audioDetails.musicAlbum,
				MusicGenre = data.asset.audioDetails.musicGenre,
				SoundEffectCategory = data.asset.audioDetails.soundEffectCategory,
				SoundEffectSubcategory = data.asset.audioDetails.soundEffectSubcategory,
			}
		end
	end

	if data.creator then
		result.Creator = {
			Id = data.creator.id,
			Name = data.creator.name,
			Type = data.creator.type,
			IsVerifiedCreator = data.creator.isVerifiedCreator,
		}
	end

	if data.product then
		result.Product = {
			ProductId = data.product.productId,
			Price = data.product.price,
		}
	end

	if data.thumbnail then
		result.Thumbnail = {
			Final = data.thumbnail.final,
			Url = data.thumbnail.url,
			RetryUrl = data.thumbnail.retryUrl,
			UserId = data.thumbnail.userId,
			EndpointType = data.thumbnail.endpointType,
		}
	end

	if data.voting then
		result.Voting = {
			ShowVotes = data.voting.showVotes,
			UpVotes = data.voting.upVotes,
			DownVotes = data.voting.downVotes,
			VoteCount = data.voting.voteCount,
			UpVotePercent = data.voting.upVotePercent,
			CanVote = data.voting.canVote,
			UserVote = data.voting.userVote,
			HasVoted = data.voting.hasVoted,
			ReasonForNotVoteable = data.voting.reasonForNotVoteable,
		}
	end

	return result
end

AssetInfo.fromCreationsDetails = function(data, assetType, creatorName, creatorType): AssetInfo
	local result = AssetInfo.new()

	result.Asset = {
		Description = data.description,
		Id = data.assetId,
		Name = data.name,
		TypeId = assetType and assetType.Value,
		AssetGenres = {},
		Status = data.status,
	}

	result.Creator = {
		Id = data.creatorTargetId,
		Name = creatorName,
		Type = creatorType,
	}

	return result
end

return AssetInfo
