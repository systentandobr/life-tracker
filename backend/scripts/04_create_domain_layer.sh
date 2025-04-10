#!/bin/bash
# Creates domain layer entities and repositories
if [ $# -lt 1 ]; then echo "Usage: $0 <base_dir>"; exit 1; fi
BASE_DIR=$1

# Basic asset entity
mkdir -p $BASE_DIR/internal/domain/asset/entity
cat > $BASE_DIR/internal/domain/asset/entity/asset.go << 'EOT'
package entity

import "time"

type AssetType string

const (
	AssetTypeStock  AssetType = "stock"
	AssetTypeREIT   AssetType = "reit"
	AssetTypeCrypto AssetType = "crypto"
)

type Asset interface {
	GetID() string
	GetSymbol() string
	GetName() string
	GetType() AssetType
	GetCurrentPrice() float64
	GetChangePercentage() float64
	SetCurrentPrice(price float64)
	IsFavorite() bool
	SetFavorite(favorite bool)
}

type BaseAsset struct {
	ID               string    `json:"id" bson:"_id"`
	Symbol           string    `json:"symbol" bson:"symbol"`
	Name             string    `json:"name" bson:"name"`
	Type             AssetType `json:"type" bson:"type"`
	CurrentPrice     float64   `json:"currentPrice" bson:"current_price"`
	PreviousClose    float64   `json:"previousClose" bson:"previous_close"`
	ChangePercentage float64   `json:"changePercentage" bson:"change_percentage"`
	LastUpdated      time.Time `json:"lastUpdated" bson:"last_updated"`
	Favorite         bool      `json:"isFavorite" bson:"is_favorite"`
}

// Implement Asset interface methods
func (a *BaseAsset) GetID() string                { return a.ID }
func (a *BaseAsset) GetSymbol() string            { return a.Symbol }
func (a *BaseAsset) GetName() string              { return a.Name }
func (a *BaseAsset) GetType() AssetType           { return a.Type }
func (a *BaseAsset) GetCurrentPrice() float64     { return a.CurrentPrice }
func (a *BaseAsset) GetChangePercentage() float64 { return a.ChangePercentage }
func (a *BaseAsset) IsFavorite() bool             { return a.Favorite }
func (a *BaseAsset) SetFavorite(favorite bool)    { a.Favorite = favorite }

func (a *BaseAsset) SetCurrentPrice(price float64) {
	a.PreviousClose = a.CurrentPrice
	a.CurrentPrice = price
	a.ChangePercentage = ((price - a.PreviousClose) / a.PreviousClose) * 100
	a.LastUpdated = time.Now()
}

// Specific asset types
type Stock struct {
	BaseAsset
	Company         string  `json:"company" bson:"company"`
	Sector          string  `json:"sector" bson:"sector"`
	DividendYield   float64 `json:"dividendYield" bson:"dividend_yield"`
	PriceToEarnings float64 `json:"priceToEarnings" bson:"price_to_earnings"`
	MarketCap       float64 `json:"marketCap" bson:"market_cap"`
}

type REIT struct {
	BaseAsset
	Segment       string  `json:"segment" bson:"segment"`
	DividendYield float64 `json:"dividendYield" bson:"dividend_yield"`
	PropertyCount int     `json:"propertyCount" bson:"property_count"`
	PVP           float64 `json:"pvp" bson:"pvp"`
}

type Cryptocurrency struct {
	BaseAsset
	MarketCap         float64    `json:"marketCap" bson:"market_cap"`
	CirculatingSupply float64    `json:"circulatingSupply" bson:"circulating_supply"`
	MaxSupply         *float64   `json:"maxSupply,omitempty" bson:"max_supply,omitempty"`
}
EOT

# Repository interface
mkdir -p $BASE_DIR/internal/domain/asset/repository
cat > $BASE_DIR/internal/domain/asset/repository/asset_repository.go << 'EOT'
package repository

import (
	"context"

	"github.com/systentandobr/life-tracker/backend/invest-tracker/internal/domain/asset/entity"
)

type AssetRepository interface {
	// Basic CRUD
	GetByID(ctx context.Context, id string) (entity.Asset, error)
	GetBySymbol(ctx context.Context, symbol string, assetType entity.AssetType) (entity.Asset, error)
	GetAll(ctx context.Context, filter map[string]interface{}) ([]entity.Asset, error)
	GetByType(ctx context.Context, assetType entity.AssetType) ([]entity.Asset, error)
	Save(ctx context.Context, asset entity.Asset) error
	Update(ctx context.Context, asset entity.Asset) error
	
	// Specialized queries
	GetFavorites(ctx context.Context) ([]entity.Asset, error)
	UpdatePrice(ctx context.Context, id string, price float64) error
	Search(ctx context.Context, query string, types []entity.AssetType) ([]entity.Asset, error)
}

// Common error types
var (
	ErrAssetNotFound = NewRepositoryError("asset not found")
	ErrDuplicateAsset = NewRepositoryError("asset already exists")
)

type RepositoryError struct {
	Message string
}

func (e RepositoryError) Error() string {
	return e.Message
}

func NewRepositoryError(message string) RepositoryError {
	return RepositoryError{Message: message}
}
EOT

echo "Domain layer created successfully"
