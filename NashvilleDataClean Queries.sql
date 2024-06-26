
/*1. To clean the property address column by filling in for null entries.

First we join the table on itself to view the entries with null values. we have found according to the data given
that all parcels with the same id have the same propertyaddress. 
using this to our advantage we can populate the null entries with referenced addresses from matching parcelid entries*/

use proX

select b.[UniqueID ], a.ParcelID, a.PropertyAddress,b.[UniqueID ], b.ParcelID, b.PropertyAddress 
from NashvilleData as a join  NashvilleData as b on 
a.ParcelID=b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
where b.PropertyAddress is null

--Now we update the null property colums with the new data fetched from rows with same parcel ID
update a set PropertyAddress=ISNULL(a.propertyaddress,b.PropertyAddress) 
from NashvilleData a join  NashvilleData b on 
a.parcelid=b.parcelid and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
----------------------------------------------------------------------------------------------------------------------------------------------
/*2. Seperating one adreess into respective parts.
As seen our propertyaddress column in the table is one continuous text. We can break it down  into respective city and state*/

--Here we use a substring to fetch text upto the first comma (,) in our address.
--The nested charindex helps us locate the first comma
select propertyaddress ,SUBSTRING(PropertyAddress,1,CHARINDEX(',',propertyaddress)-1) New_State,
SUBSTRING(PropertyAddress,CHARINDEX(',',propertyaddress)+1, LEN(propertyaddress)) as New_city
from NashvilleData

--We add the new columns
alter table NashvilleData add city varchar(100), state varchar(100);

--and insert the new data from our query
update NashvilleData set city=SUBSTRING(PropertyAddress,1,CHARINDEX(',',propertyaddress)-1),
state=SUBSTRING(PropertyAddress,CHARINDEX(',',propertyaddress)+1, LEN(propertyaddress))

select * from NashvilleData where owneraddress is not null


--3. Seperating the owner address into individual state, city and street using ParseInt and replace

--Here we use the pasrse int function to locate the first full stop. But since the column contains one continuous text address seperated by commas
--we use the replace function to replace every comma with a period.
select owneraddress,
PARSEname(replace(owneraddress,',','.'),1) as State,
PARSEname(replace(owneraddress,',','.'),2) as City,
PARSEname(replace(owneraddress,',','.'),3) as Street from NashvilleData
where OwnerAddress is not null

--We add the new columns
alter table NashvilleData add OwnerState Nvarchar(225),OwnerCity nvarchar(225), OwnerStreet nvarchar(225)

--and insert the new data from our query
update NashvilleData set 
Ownerstate=PARSEname(replace(owneraddress,',','.'),1),
Ownercity=PARSEname(replace(owneraddress,',','.'),2),
Ownerstreet=PARSEname(replace(owneraddress,',','.'),3)


--4.Using the CASE function to alter the data of a particular column

--To view the houses that where sold as vacant
select distinct (SoldAsVacant),count(SoldAsVacant) from NashvilleData
group by soldasvacant
order by 2

--To test the query that changes Y to Yes and N to No in the SoldAsVacant column
select SoldAsVacant,
case 
when SoldAsVacant='Y' then 'Yes'
when SoldAsVacant='N' then 'No'
else SoldAsVacant
end
from NashvilleData

--Now we insert the results of our query into the table under the SoldAsVacant column
update NashvilleData set Soldasvacant=
case 
when SoldAsVacant='Y' then 'Yes'
when SoldAsVacant='N' then 'No'
else SoldAsVacant
end


--5. Deleting Duplicatees using partition by.

/* Here I use the row number and the over function to add an icrement to an entry that iscontaains the same data by partitioned columns.
This way all duplicates will return a value thats greater than 1 in the new column named RowNum */

select * ,
ROW_NUMBER() over(partition by parcelid,saleprice,saledate,legalreference order by uniqueid) as RowNum 
from NashvilleData

/* Now seeing that we cant use the column we just created to sort our results, 
Our other alternative is to throw our data into a CTE tabllle and query from it */\

with CTEDamp as
(
select * ,
ROW_NUMBER() over(partition by parcelid,saleprice,saledate,legalreference order by uniqueid) as RowNum 
from NashvilleData
)
select * from CTEDamp where RowNum <> 1
/*Uncomment query below to delete duplicates from database*/
--delete  from CTEdamp where RowNum>1


/*6.Cleaning the Saledate column and gettiing rid of the extra time information*/
select SaleDate from NashvilleData
alter table NashvilleData add SaleDatex date
Update NashvilleData set SaleDatex=CONVERT(date,saledate)

/*7. Deleting columns that arent needed anymore
Since we have cleaned the owneraddress, propertyaddress and saledate columns, there isn't much need for them in our table.
*/
alter table NashvilleData drop column saleDatex,OwnerAddress,Propertyaddress
