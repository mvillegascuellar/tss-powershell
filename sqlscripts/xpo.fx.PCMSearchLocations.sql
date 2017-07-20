CREATE FUNCTION [dbo].[PCMSearchLocations](@zipCode [nvarchar](4000), @cityState [nvarchar](4000), @searchMode [int])
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMSearchLocations]
;