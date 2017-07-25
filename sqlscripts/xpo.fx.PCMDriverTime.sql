CREATE FUNCTION [dbo].[PCMDriverTime](@zip1 [nvarchar](4000), @zip2 [nvarchar](4000))
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMDriverTime]
;