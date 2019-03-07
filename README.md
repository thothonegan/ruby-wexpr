# Wexpr

Ruby parser for the Wexpr format. See [libWexpr](https://github.com/thothonegan/libWexpr) for more details of the format.

Current limitations:
- Does not currently support the binary format.
- Does not have `Wexpr.dump` for turning a ruby hash into the equivilant wexpr string.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wexpr', :git => "git://github.com/thothonegan/ruby-wexpr.git"
```

And then execute:

    $ bundle

Currently it is not published to rubygems.

## Usage

For simple wexpr expression to an equivilant ruby hash (similar to yaml/json libraries):
```ruby
require 'wexpr'

rubyHash = Wexpr.load("@(array #(1 2 3)")

```

For more complex, `Wexpr::Expression` acts like its libWexpr equivilant. See the files in [test](./test/) for examples.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thothonegan/ruby-wexpr.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
