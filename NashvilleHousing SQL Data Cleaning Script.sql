/* CLEANING DATA IN SQL QUERIES */

-- Initial inspection of the NashvilleHousing table.
SELECT *
FROM NashvilleHousing

-------------------------------------------------------------------------------------------------------------

-- Standardizing Date Format:
SELECT SaleDate, CONVERT(date, SaleDate)
FROM NashvilleHousing

-- Updating SaleDate in NashvilleHousing table to a standardized date format.
UPDATE NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)


-- Adding a new column SaleDateConverted to store the standardized date format.
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

-- Populating SaleDateConverted with the converted date values.
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)


--------------------------------------------------------------------------------------------------------------

-- Populating Property Address column:

-- Identifying records with missing PropertyAddress values.
SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID


-- Joining NashvilleHousing table to itself to fill in missing PropertyAddress values based on ParcelID.
SELECT AA.ParcelID, AA.PropertyAddress, BB.ParcelID, BB.PropertyAddress, ISNULL(AA.PropertyAddress, BB.PropertyAddress)
FROM NashvilleHousing AA
JOIN NashvilleHousing BB ON AA.ParcelID = BB.ParcelID AND AA.[UniqueID ] <> BB.[UniqueID ]
WHERE AA.PropertyAddress IS NULL


-- Updating missing PropertyAddress values in NashvilleHousing table using a self-join.
UPDATE AA
SET PropertyAddress = ISNULL(AA.PropertyAddress, BB.PropertyAddress)
FROM NashvilleHousing AA
JOIN NashvilleHousing BB ON AA.ParcelID = BB.ParcelID AND AA.[UniqueID ] <> BB.[UniqueID ]
WHERE AA.PropertyAddress IS NULL

---------------------------------------------------------------------------------------------------------------

-- Breaking Property Address into indivdual columns (Address, City, State):

-- Extracting Address and City from PropertyAddress.
SELECT PropertyAddress 
FROM NashvilleHousing

-- Splitting PropertyAddress into separate Address and City columns.
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
       SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

-- Adding columns for split address and city in NashvilleHousing table.
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);


ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));


-- Using PARSENAME to further split OwnerAddress into Address, City, and State components.
SELECT OwnerAddress
FROM NashvilleHousing;

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing;

-- Adding and populating columns for split owner address, city, and state.
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);


ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


SELECT *
FROM NashvilleHousing;

------------------------------------------------------------------------------------------------------------

-- Changing 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant column:

-- Reviewing the distribution of SoldAsVacant values.
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Previewing the conversion of 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant column.
SELECT SoldAsVacant,
       CASE WHEN SoldAsVacant = 'N' THEN 'No'
            WHEN SoldAsVacant ='Y' THEN 'Yes'
            ELSE SoldAsVacant
       END
FROM NashvilleHousing

-- Updating the SoldAsVacant column to reflect 'Yes' or 'No' instead of 'Y' or 'N'.
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No'
                        WHEN SoldAsVacant ='Y' THEN 'Yes'
                        ELSE SoldAsVacant
                    END;

-------------------------------------------------------------------------------------------------------------

-- Removing Duplicates:

-- Identifying duplicate records within the NashvilleHousing table using a Common Table Expression (CTE). 
-- The CTE is used to assign row numbers to each record, partitioned by 
--	ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference, with rows ordered by UniqueID.
WITH RowNumCTE AS (
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
           ORDER BY UniqueID
       ) RowNum
FROM NashvilleHousing
)

-- Selecting duplicates identified by the RowNumCTE for review before deletion. 
-- Duplicates are considered any records with a RowNum greater than 1 within each partition set.
SELECT *
FROM RowNumCTE
WHERE RowNum > 1 
ORDER BY PropertyAddress

-- Deleting duplicate records from NashvilleHousing based on RowNumCTE criteria, specifically targeting records 
--	with a RowNum greater than 1, which are identified as duplicates.
DELETE
FROM RowNumCTE
WHERE RowNum > 1 


-------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns:

-- Inspecting the NashvilleHousing table to determine the structure and existing columns before dropping 
--	unused ones.
SELECT *
FROM NashvilleHousing

-- Dropping the OwnerAddress, TaxDistrict, PropertyAddress, and SaleDate columns from the NashvilleHousing table.
-- This operation permanently removes these columns and their data from the table, 
--	based on the determination that they are no longer needed for analysis or storage.
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

