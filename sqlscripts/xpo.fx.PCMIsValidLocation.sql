CREATE FUNCTION [dbo].[PCMIsValidLocation](@zipCode [nvarchar](4000), @cityState [nvarchar](4000))
RETURNS [bit] WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMIsValidLocation]
;