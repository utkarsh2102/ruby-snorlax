# Snorlax

![](http://img3.wikia.nocookie.net/__cb20140924022259/pokemon/images/9/9f/143Snorlax_OS_anime.png)

Snorlax is an opinionated, flexible, and well-RESTed gem for building Rails APIs. It's designed to Do The Right Thing™ by default, but allow you to customize where necessary.

It's been extracted from [Loomio](www.github.com/loomio/loomio).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'snorlax'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snorlax

## Usage

There are two primary ways to use Snorlax. The easier way is to inherit from it:

```
class MyController < Snorlax::Base
end
```

But, if you're already inheriting from something else, Snorlax makes it easy to simply apply itself to your controller without being a parent, by calling `snorlax_used_rest!` like so:

```
class MyController < SomeOtherController
  snorlax_used_rest!
end
```

Once you've got it installed, you're good to go!

#### Some things to know about Snorlax:

Snorlax is designed to provide a set of flexible API endpoints for client side consumption. It uses side loading, which means that all of the records returned are unnested and easily available for consumption.

#### The show action

By default, Snorlax will fetch the requested model by `id` using the `ActiveModel::Base.find` method. To override this behaviour, you may override the `load_resource` method in your controller.

```
class TaurosController < Snorlax::Base
  def load_resource
    SafariZone.find(params[:id])
  end
end
```

NB: This would be a great place to ensure that the current user is allowed to view the requested resource.

#### The index action

Snorlax DEMANDS that you define two separate methods for the index action to work properly:
- `public_records` - records which are available publicly (ie, they can be viewed even if current_user is nil)
- `visible_records` - records which the current user is allowed to access.

```
class StaryusController < Snorlax::Base
  def public_records
    Staryu.visible_to_public
  end

  def visible_records
    current_user.staryus
  end
end
```
If these are the same, you may override the `accessible_records` method instead

```
class StarmiesController < Snorlax::Base
  def accessible_records
    Starmie.all
  end
end
```

The default index action look like this:

```
def index
  instantiate_collection
  respond_with_collection
end
```

but there are many options to customize it.

##### Paging the index action

A Snorlax controller can accept `from` and `per` parameters for paging. For example,

```
/api/vi/psyducks?from=0&per=100
```

will return the first 100 psyducks within the accessible records.

If no `from` or `per` params are provided, Snorlax will default to the first 50 records. (from = 0, per = 50)

You can override the default page size by overriding the `default_page_size` method.

```
class WobbuffetsController < Snorlax::Base
  def default_page_size
    25
  end
end
```

##### Timeframing the index action

A Snorlax controller can accept `since` and `until` parameters for timeframing. The date it looks for defaults to `created_at`. For example,

```
/api/v1/charmanders?since=11-11-2011&until=12-12-2012
```

will return charmanders which were created between Nov 11, 2011, and Dec 12, 2012.

You can override the datetime column the query looks at by passing the `timeframe_for` option. For example,

```
/api/v1/charmeleons?since=11-11-2011&until=12-12-2012&timeframe_for=evolved_at
```

will return charmeleons which evolved between Nov 11, 2011, and Dec 12, 2012

Since and until can be in any format that `Date.parse` will accept.

##### Overriding the timeframing or pagination options

If you want to disallow timeframing and/or pagination for a particular action, simple pass `timeframe_collection: false` or `page_collection: false` when the collection is instantiated.

```
class SquirtlesController < Snorlax::Base
  def all_squirtles
    instantiate_collection page_collection: false, timeframe_collection: false
    respond_with_collection
  end
end
```

##### Custom filtering on the index action

Snorlax also provides a dead simple way to provide your own filters, in addition to and in combination with the ones provided.
You can do this by passing a block to the `instantiate_collection` method in your controller action. For example,

```
class ChanseysController < Snorlax::Base
  def sleeping
    instantiate_collection { |collection| collection.where(sleeping: true) }
    respond_with_collection
  end
end
```

Will return all sleeping Chanseys. (This can be combined with timeframing and paginating as well.)
(NB: this filtering happens before the collection is paginated or timeframed, so it's a good opportunity to add additional filters
or apply an order to your records. Or both!)

##### Customizing the serializer options

By default, Snorlax will find a serializer based on the controller name, and serialize out your collection of records with a root.

##### To override serializer and root for all actions in the controller

You can override the serializer being used or the serializer root across the controller by defining a `resource_serializer` or `serializer_root` method, respectively:
```
class DittosController < Snorlax::Base
  def resource_serializer
    PokemonSerializer
  end

  def serializer_root
    :pokemon
  end
end
```

This will result is JSON like this:
```
{ pokemon: [{ pokemon_serializer_field_a: 'valueA', pokemon_serializer_field_b: 'valueB' }] }
```

##### To override serializer and root for a single action

To do this for a particular action, pass the `serializer` or `root` option to respond_with_collection.
(NB: You can also pass a scope to the serializer in this way, by passing a 'scope' option)

```
class DittosController < Snorlax::Base
  def index
    instantiate_collection
    respond_with_collection serializer: PokemonSerializer, root: :pokemon, scope: { is_ditto: true }
  end
end
```

#### The create / update actions

By default, Snorlax will load the requested resource, perform an action on it, and then respond with the resource (with the same response as the show action) It looks like this:

```
def create
  instantiate_resource
  create_action
  respond_with_resource
end

def create_action
  resource.save
end
```

##### Overriding the action command

If you have more complicated logic for creating or updating records (your creation / update logic is wrapped up in a service object, for example), simply override the `create_action` method (or the `update_action` method in the case of update)

```
def MewtwosController < Snorlax::Base
  def create_action
    Science.faff_about(resource_params)
  end
end
```

(NB: this is a good opportunity to make sure that the current user has permission to modify the record.)

##### Overriding the resource serialization

`respond_with_resource` accepts the same parameters as respond_with_collection, to allow for single-action customization of the json response.

```
def MewtwosController < Snorlax::Base
  def create
    instantiate_resource
    create_action
    respond_with_resource { serializer: LegendarySerializer, root: 'legendary_pokemon' }
  end
end
```

##### If there are errors on the object

TODO: explain the respond_with_errors behaviour

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gdpelican/snorlax. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
