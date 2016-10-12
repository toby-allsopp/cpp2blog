module Main where

import           Data.List
import           Data.Maybe
import           System.Environment
import           System.FilePath

data Block = Source [String] | Doc [String]

data State = AtStart | InSource [String] [Block] | InDoc (Maybe String) [String] [Block]

classify :: String -> [Block]
classify input =
  stateOutput $ foldl' process' AtStart $ lines input
  where
    process' :: State -> String -> State
    process' AtStart line =
      if isStartDoc line then
        InDoc Nothing [] []
      else
        InSource [line] []
    process' (InSource lines output) line =
      if isStartDoc line then
        InDoc Nothing [] (Source lines : output)
      else
        InSource (lines ++ [line]) output
    process' (InDoc leading lines output) line =
      if isEndDoc line then
        InSource [] (Doc lines : output)
      else
        let (newLeading, strippedLine) = stripLeadingIndent leading line in
          InDoc newLeading (lines ++ [strippedLine]) output

    isStartDoc = isInfixOf "/*!"
    isEndDoc = isInfixOf "*/"

    stripLeadingIndent leading [] = (leading, [])
    stripLeadingIndent (Just prefix) line =
      (Just prefix, fromMaybe line $ stripPrefix prefix line)
    stripLeadingIndent Nothing line =
      let indent = detectLeadingIndent line "" in
        stripLeadingIndent (Just indent) line

    detectLeadingIndent [] indent = indent
    detectLeadingIndent (c:cs) indent | c == ' ' = detectLeadingIndent cs (c:indent)
                                      | otherwise = indent

    stateOutput AtStart                 = []
    stateOutput (InSource lines output) = reverse $ Source lines : output
    stateOutput (InDoc _ lines output)  = reverse $ Doc lines : output

markdownOutput :: [Block] -> String
markdownOutput =
  unlines . concatMap (surroundWith [""] [""] . markdownBlock)
  where
    surroundWith before after lines = before ++ lines ++ after
    trimBlankLines = reverse . trimLeadingBlanks . reverse . trimLeadingBlanks
    trimLeadingBlanks ([]:xs) = trimLeadingBlanks xs
    trimLeadingBlanks xs      = xs

    startOfSourceBlock = ["~~~c++"]
    endOfSourceBlock = ["~~~", "{: .cpp2blog-source}"]

    markdownBlock :: Block -> [String]
    markdownBlock (Source lines) =
      surroundWith startOfSourceBlock endOfSourceBlock $ trimBlankLines lines
    markdownBlock (Doc lines) = lines

process :: String -> String
process =
  markdownOutput . classify

processFile :: String -> IO ()
processFile file = do
  putStrLn $ "> " ++ takeFileName file
  putStrLn ""
  contents <- readFile file
  let output = process contents
  putStr output

main :: IO ()
main = getArgs >>= mapM_ processFile
