CREATE FUNCTION [dbo].[PCMMiles](@zip1 [nvarchar](4000), @zip2 [nvarchar](4000))
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMMiles]
GO
EXEC sys.sp_addextendedproperty @name=N'AutoDeployed', @value=N'yes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
GO
EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFile', @value=N'PcMiler.cs' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
GO
EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFileLine', @value=11 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PCMDriverTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[PCMDriverTime]
GO
CREATE FUNCTION [dbo].[PCMDriverTime](@zip1 [nvarchar](4000), @zip2 [nvarchar](4000))
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMDriverTime]
GO
CREATE FUNCTION [dbo].[PCMZipCode](@cityst [nvarchar](4000))
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMZipCode]
GO
EXEC sys.sp_addextendedproperty @name=N'AutoDeployed', @value=N'yes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMZipCode'
GO
EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFile', @value=N'PcMiler.cs' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMZipCode'
GO
EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFileLine', @value=35 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMZipCode'
GO
/****** Object:  UserDefinedFunction [dbo].[PCMCityState]    Script Date: 12/14/2010 13:24:36 ******/
CREATE FUNCTION [dbo].[PCMCityState](@zip [nvarchar](4000))
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMCityState]
GO
EXEC sys.sp_addextendedproperty @name=N'AutoDeployed', @value=N'yes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMCityState'
GO
EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFile', @value=N'PcMiler.cs' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMCityState'
GO
EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFileLine', @value=23 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMCityState'
GO
CREATE FUNCTION [dbo].[PCMSearchLocations](@zipCode [nvarchar](4000), @cityState [nvarchar](4000), @searchMode [int])
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMSearchLocations]
GO
CREATE FUNCTION [dbo].[PCMIsValidLocation](@zipCode [nvarchar](4000), @cityState [nvarchar](4000))
RETURNS [bit] WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMIsValidLocation]
GO