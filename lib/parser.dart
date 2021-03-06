library parser;

import 'dart:async';
import 'dart:io';

import 'package:parser/parsers/russian_food.dart';

import 'models/parse_error.dart';
import 'models/parse_result.dart';
import 'parsers/eda_ru.dart';
import 'package:http/http.dart' as http;

const spaghettiLink =
    'https://eda.ru/recepty/osnovnye-blyuda/ferganskiy-plov-27690';
const brownieLink =
    'https://eda.ru/recepty/vypechka-deserty/brauni-brownie-20955';
const russianFoodLink = 'https://www.russianfood.com/recipes/recipe.php?rid=117262&ref=cro_i_1&token=129942532';

const availableSites = ['eda.ru', 'russianfood.com'];

void main(List<String> arguments) async {
  const link = russianFoodLink;
  final result = await Parser(link: link).parse();
  if (result.recipe != null) {
    final recipe = result.recipe!;
    // print(recipe.images);
    print(recipe.title);
    print(recipe.time);
    print(recipe.calories);
    print(recipe.description);
    print(recipe.link);
    print(recipe.portions);
    print(recipe.ingredients);
    print(recipe.steps);
  } else {
    print(result.error?.title);
    print(result.error?.content);
    print('Что-то пошло не так');
  }
}

class Parser {
  final String link;

  Parser({required this.link});

  Future<ParseResult> parse() async {
    if (availableSites.any((site) => link.contains(site))) {
      try {
        final response = await http.get(Uri.parse(link));
        if (response.statusCode == 200) {
          if (link.contains('eda.ru')) {
            return ParseResult(
              recipe: await EdaRuParser(
                response: response,
                link: link,
              ).parseRecipe(),
            );
          }
          if (link.contains('russianfood.com')) {
            return ParseResult(
              recipe: await RussianFoodParser(
                response: response,
                link: link,
              ).parseRecipe(),
            );
          }
        } else {
          return ParseResult(
            error: ParseError(
              title: 'Невозможно получить данные.',
              content: 'Попробуйте позже.',
            ),
          );
        }
      } on TimeoutException catch (_) {
        return ParseResult(
          error: ParseError(
            title: 'Истекло время ожидания сайта.',
            content: 'Попробуйте позже.',
          ),
        );
      } on SocketException catch (_) {
        return ParseResult(
          error: ParseError(
            title: 'Для загрузки рецепта нужен интернет.',
            content: 'Включите его в настройках.',
          ),
        );
      } catch (e) {
        return ParseResult(
          error: ParseError(
            title: e.toString(),
            content: 'Попробуйте позже.',
          ),
        );
      }
    }
    return ParseResult(
      error: ParseError(
        title: 'У нас нет парсера для этого сайта.',
      ),
    );
  }
}
