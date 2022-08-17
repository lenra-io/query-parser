<div id="top"></div>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![AGPL License][license-shield]][license-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <!-- <a href="https://github.com/lenra-io/template-hello-world-node12">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a> -->

<h3 align="center">Lenra Query Parser</h3>

  <p align="center">
    This repository provides a tool that can parse a JSON query into an AST tree and parse this tree into an Ecto query that can be executed within elixir.
    <br />
    <br />
    <!-- <a href="https://github.com/lenra-io/template-hello-world-node12">View Demo</a>
    · -->
    <a href="https://github.com/lenra-io/query-parser/issues">Report Bug</a>
    ·
    <a href="https://github.com/lenra-io/query-parser/issues">Request Feature</a>
  </p>
</div>

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

You need to add this lib into your phoenix app : 
```bash
    {:query_parser, git: "https://github.com/lenra-io/query-parser.git", tag: "v1.0.0-beta.X"}
```

<p align="right">(<a href="#top">back to top</a>)</p>

## Parser

### JSON to AST
<!-- Add the README link when this pr merge https://github.com/lenra-io/query-parser/pull/6 -->
With the parser you can parse a JSON query into an AST tree, for more 
information about the format of the JSON query consult this [README](). To parse JSON:

> $\qquad$ Add the alias:
```
  alias QueryParser.AST.Parser
```

> $\qquad$ Parse query with function:
```
  Parser.from_json(q)
```
$\qquad$ with q the JSON query

### AST to Ecto
Once you parse a JSON query into an AST tree you will be able to parse this AST into an Ecto query:

> $\qquad$ Add the alias:
```
  alias QueryParser.AST.EctoParser
```

> $\qquad$ Parse query with function:
```
  EctoParser.to_ecto(query, env_id, user_data_id)
```
$\qquad$ with:  
$\qquad$ $\qquad$ - query the AST tree  
$\qquad$ $\qquad$ - env_id the environement id  
$\qquad$ $\qquad$ - user_data_id the id of the user's user data 

you can now execute the query with ecto:

```
Repo.all(ecto_query)
Repo.one(ecto_query)
```
with ecto_query the query is parsed before, the all function returns a list of all matching results, the one function returns only one element (beware: if there is more than one result the function returns an error), to learn more about the ecto repository  [function](https://hexdocs.pm/ecto/Ecto.Repo.html#query-api)

### Two step together:

> $\qquad$ Add the alias:
```
  alias QueryParser.AST.{EctoParser, Parser}
```

> $\qquad$ Parse query with function:
```
  Query
  |> Parser.from_json()
  |> EctoParser.to_ecto(env_id, user_data_id)
  |> Repo.all()
```


<p align="right">(<a href="#top">back to top</a>)</p>


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please open an issue with the tag "enhancement" or "bug".
Don't forget to give the project a star! Thanks again!

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the **AGPL** License. See [LICENSE](./LICENSE) for more information.

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Lenra - [@lenra_dev](https://twitter.com/lenra_dev) - contact@lenra.io

Project Link: [https://github.com/lenra-io/query-parser](https://github.com/lenra-io/query-parser)

<p align="right">(<a href="#top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/lenra-io/query-parser.svg?style=for-the-badge
[contributors-url]: https://github.com/lenra-io/query-parser/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/lenra-io/query-parser.svg?style=for-the-badge
[forks-url]: https://github.com/lenra-io/query-parser/network/members
[stars-shield]: https://img.shields.io/github/stars/lenra-io/query-parser.svg?style=for-the-badge
[stars-url]: https://github.com/lenra-io/query-parser/stargazers
[issues-shield]: https://img.shields.io/github/issues/lenra-io/query-parser.svg?style=for-the-badge
[issues-url]: https://github.com/lenra-io/query-parser/issues
[license-shield]: https://img.shields.io/github/license/lenra-io/query-parser.svg?style=for-the-badge
[license-url]: https://github.com/lenra-io/query-parser/blob/master/LICENSE
